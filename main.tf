data "aws_caller_identity" "current" {}

provider "aws" {
  alias  = "us-east-1"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${admin_role}"
  }
}

provider "aws" {
  alias  = "us-west-2"
  region = var.second_region
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${admin_role}"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
  }
}
