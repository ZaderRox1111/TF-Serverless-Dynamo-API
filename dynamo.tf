resource "aws_dynamodb_table" "table" {
  // Basic setup
  hash_key         = "id"
  name             = "basic-table"
  billing_mode     = "PROVISIONED"
  read_capacity    = 1
  write_capacity   = 1
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  // Adding attributes and the hash key
  // Can be of type S (string), N (number), or B (binary)
  attribute {
    name = "id"
    type = "N"
  }

  // If you need to add tags
  tags = {
    course = var.course
  }
}