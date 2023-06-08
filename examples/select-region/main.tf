terraform {
  required_version = ">= 1.1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.3"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {
}

resource "aws_iam_user" "admin" {
  name = "admin"
}

module "secure_baseline" {
  source = "../../"

  audit_log_bucket_name           = var.audit_s3_bucket_name
  aws_account_id                  = data.aws_caller_identity.current.account_id
  region                          = var.region
  support_iam_role_principal_arns = [aws_iam_user.admin.arn]
  target_regions                  = ["us-gov-west-1", "us-gov-west-1"]

  # Setting it to true means all audit logs are automatically deleted
  #   when you run `terraform destroy`.
  # Note that it might be inappropriate for highly secured environment.
  audit_log_bucket_force_destroy = true

  # This module only configure regions specified in target_regions argument though,
  # all providers still need to be passed to the module.
  providers = {
    aws               = aws
    aws.us-gov-west-1 = aws.us-gov-west-1
    aws.us-gov-east-1 = aws.us-gov-east-1
  }
}
