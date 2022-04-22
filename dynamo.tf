resource "aws_dynamodb_table" "table" {
  depends_on = [aws_kms_key.ddbv2_encryption_key, null_resource.replicate_key, null_resource.put_key_policy_usw2]
  
  // Provisioned is no longer available with global tables
  hash_key         = "id"
  name             = "basic-table"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  // Adding attributes and the hash key
  // Can be of type S (string), N (number), or B (binary)
  attribute {
    name = "id"
    type = "N"
  }

  // Adding our own encryption with our KMS CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.ddbv2_encryption_key.arn
  }

  // If you need to add tags
  tags = {
    course = var.course
  }

  // Creating the replica / global table
  replica {
    region_name = var.second_region
    kms_key_arn = replace(aws_kms_key.ddbv2_encryption_key.arn, var.region, var.second_region)
  }
}

// Replicate the tags in a similar way as the key replication
resource "null_resource" "replicate_table_tags_usw2" {
  depends_on = [aws_dynamodb_table.table]

  // Add a trigger so that it will happen every apply
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws dynamodb tag-resource --resource-arn ${replace(aws_dynamodb_table.table.arn, var.region, var.second_region)} --tags 'Key'='course','Value'='${var.course}' --region ${var.second_region}"
  }
}
