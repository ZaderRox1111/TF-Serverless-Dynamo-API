resource "aws_iam_role_policy" "lambda_policy" {
  name     = "lambda_policy"
  role     = aws_iam_role.role_for_LDC.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/*"
    },
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/ddbLambda:*"
    },
    {
      "Sid": "NetworkInterface",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeInstances",
        "ec2:DeleteNetworkInterface",
        "ec2:CreateMetworkInterface",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSDecrypt",
      "Effect": "Allow",
      "Action": ["kms:*"],
      "Resource": "*"
    }]
  })
}

resource "aws_iam_role" "role_for_LDC" {
  name = "ddbLambda"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

// Lambda function
resource "aws_lambda_function" "lambda" {
  depends_on = [aws_kms_key.ddbv2_encryption_key]

  function_name = "ddbLambda"
  s3_bucket     = "tf-hon-408-s3-bucket"
  s3_key        = aws_s3_object.file_upload.key
  role          = aws_iam_role.role_for_LDC.arn
  handler       = "ddbLambda.handler"
  runtime       = "nodejs12.x"

  kms_key_arn = aws_kms_key.ddbv2_encryption_key.arn
}

// Defining Lambda and Api permissions
resource "aws_lambda_permission" "lambda_permission" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal = "apigateway.amazonaws.com"

  // Allows requests from any route on stage test
  source_arn = "${aws_api_gateway_rest_api.rest_api.execution_arn}/test/*/*"
}
