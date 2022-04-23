// VERY IMPORTANT: on Terraform AWS 4.0+ the s3 bucket creation changed drastically
// Make sure you are looking at the new docs on Terraform to make s3 buckets
resource "aws_s3_bucket" "encryption" {
  bucket = "tf-hon-408-s3-bucket"

  tags = {
    course = var.course
  }
}

// Making it private
resource "aws_s3_bucket_acl" "encryption" {
  bucket = aws_s3_bucket.encryption.id
  acl    = "private"
}

// Creating the zip file
data "archive_file" "ddbLambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ddbLambda"
  output_path = "${path.module}/lambda/ddbLambda.zip"
}

resource "aws_s3_object" "file_upload" {
  depends_on = [data.archive_file.ddbLambda_zip]

  bucket = aws_s3_bucket.encryption.id
  key    = "lambda/ddbLambda.zip"
  source = data.archive_file.ddbLambda_zip.output_path
}
