terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  # State is local — *.tfstate is gitignored.
  # For production, replace with an S3 backend:
  #
  # backend "s3" {
  #   bucket = "your-tf-state-bucket"
  #   key    = "agentcore/hello-world/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "agent_code" {
  bucket        = "bedrock-agentcore-code-${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true
}

resource "aws_s3_object" "agent_package" {
  bucket = aws_s3_bucket.agent_code.bucket
  key    = "hello-world/agent.zip"
  source = "${path.module}/../dist/agent.zip"
  etag   = filemd5("${path.module}/../dist/agent.zip")
}

output "s3_uri" {
  value = "s3://${aws_s3_bucket.agent_code.bucket}/hello-world/agent.zip"
}
