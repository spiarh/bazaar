terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "bucket_a" {}
variable "bucket_b" {}

resource "aws_s3_bucket" "a" {
  bucket = var.bucket_a
  acl    = "private"

  tags = {
    Name        = "gardener"
    Environment = "Test"
  }
}

resource "aws_s3_bucket" "b" {
  bucket = var.bucket_b
  acl    = "private"

  tags = {
    Name        = "gardener"
    Environment = "Test"
  }
}

output "bucket_names" {
    value = [aws_s3_bucket.a.bucket, aws_s3_bucket.b.bucket]
}
