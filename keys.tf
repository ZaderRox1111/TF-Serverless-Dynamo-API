data "aws_iam_policy_document" "ddb_key_policy" {
  policy_id = "hon-408-ddb-key-policy"

  statement {
    sid     = "Deployer has full access"
    actions = ["kms:*"]

    principals {
      type = "AWS"
      // MUST be root user for all of these or else you get AccessDeniedError on Lambda
      identifiers = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" ]
    }

    resources = [ "*" ]
  }

  statement {
    sid     = "AWS permissions for cloudwatch logging"
    actions = [ "kms:GenerateDataKey*", "kms:Decrypt", "kms:Encrypt" ]

    principals {
      type        = "Service"
      identifiers = [ "cloudwatch.amazonaws.com", "s3.amazonaws.com", "events.amazonaws.com" ]
    }

    resources = [ "*" ]
  }
}

// Send the policy document to a json so we can use it
resource "local_file" "kms_policy_json" {
  content  = data.aws_iam_policy_document.ddb_key_policy.json
  filename = "${path.module}/output/kmsPolicy.json"
}

// Actually create the key using the permissions from the IAM policy
resource "aws_kms_key" "ddbv2_encryption_key" {
  description         = "This key is used in HON408 to encrypt V2 ddb tables"
  policy              = data.aws_iam_policy_document.ddb_key_policy.json
  enable_key_rotation = true
  multi_region        = true
}

resource "aws_kms_alias" "ddb_key_alias-use1" {
  name = "alias/us-east-1-hon-408-ddb"
  target_key_id = aws_kms_key.ddbv2_encryption_key.id
}

// Key replication portion
// We need to make a second key that we can use on the second region of the table
// You need to download the aws cli in order to run this
resource "null_resource" "replicate_key" {
  depends_on = [ aws_kms_key.ddbv2_encryption_key ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws kms replicate-key --key-id ${aws_kms_key.ddbv2_encryption_key.id} --replica-region ${var.second_region} --policy file://${path.module}/output/kmsPolicy.json --region ${var.region} --description 'Second region encryption'"
  }
}

resource "null_resource" "put_key_policy_usw2" {
  depends_on = [null_resource.replicate_key]

  // Add a trigger so that it will happen every apply
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws kms put-key-policy --key-id ${aws_kms_key.ddbv2_encryption_key.id} --policy-name default --policy file://${path.module}/output/kmsPolicy.json --region ${var.second_region}"
  }
}

resource "aws_kms_alias" "ddb_key_alias_usw2" {
  name = "alias/us-west-2-hon-408-ddb"
  target_key_id = aws_kms_key.ddbv2_encryption_key.id
}
