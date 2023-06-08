locals {
  flow_logs_to_cw_logs = var.vpc_enable && var.vpc_enable_flow_logs && (var.vpc_flow_logs_destination_type == "cloud-watch-logs")
  flow_logs_to_s3      = var.vpc_enable && var.vpc_enable_flow_logs && (var.vpc_flow_logs_destination_type == "s3")
  flow_logs_s3_arn = local.flow_logs_to_s3 ? (
    var.vpc_flow_logs_s3_arn != "" ? var.vpc_flow_logs_s3_arn : local.audit_log_bucket_arn
  ) : ""
}

# --------------------------------------------------------------------------------------------------
# Create an IAM Role for publishing VPC Flow Logs into CloudWatch Logs group.
# Reference: https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/flow-logs.html#flow-logs-iam
# --------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "flow_logs_publisher_assume_role_policy" {
  count = local.flow_logs_to_cw_logs ? 1 : 0

  statement {
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_logs_publisher" {
  count = local.flow_logs_to_cw_logs ? 1 : 0

  name               = var.vpc_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.flow_logs_publisher_assume_role_policy[0].json

  permissions_boundary = var.permissions_boundary_arn

  tags = var.tags
}

data "aws_iam_policy_document" "flow_logs_publish_policy" {
  count = local.flow_logs_to_cw_logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_publish_policy" {
  count = local.flow_logs_to_cw_logs ? 1 : 0

  name = var.vpc_iam_role_policy_name
  role = aws_iam_role.flow_logs_publisher[0].id

  policy = data.aws_iam_policy_document.flow_logs_publish_policy[0].json
}

# --------------------------------------------------------------------------------------------------
# VPC Baseline
# Needs to be set up in each region.
# --------------------------------------------------------------------------------------------------

module "vpc_baseline_us-gov-west-1" {
  count  = var.vpc_enable && contains(var.target_regions, "us-gov-west-1") ? 1 : 0
  source = "./modules/vpc-baseline"

  providers = {
    aws = aws.us-gov-west-1
  }

  enable_flow_logs            = var.vpc_enable_flow_logs
  flow_logs_destination_type  = var.vpc_flow_logs_destination_type
  flow_logs_log_group_name    = var.vpc_flow_logs_log_group_name
  flow_logs_iam_role_arn      = local.flow_logs_to_cw_logs ? aws_iam_role.flow_logs_publisher[0].arn : null
  flow_logs_retention_in_days = var.vpc_flow_logs_retention_in_days
  flow_logs_s3_arn            = local.flow_logs_s3_arn
  flow_logs_s3_key_prefix     = var.vpc_flow_logs_s3_key_prefix

  tags = var.tags
}

module "vpc_baseline_us-gov-east-1" {
  count  = var.vpc_enable && contains(var.target_regions, "us-gov-east-1") ? 1 : 0
  source = "./modules/vpc-baseline"

  providers = {
    aws = aws.us-gov-east-1
  }

  enable_flow_logs            = var.vpc_enable_flow_logs
  flow_logs_destination_type  = var.vpc_flow_logs_destination_type
  flow_logs_log_group_name    = var.vpc_flow_logs_log_group_name
  flow_logs_iam_role_arn      = local.flow_logs_to_cw_logs ? aws_iam_role.flow_logs_publisher[0].arn : null
  flow_logs_retention_in_days = var.vpc_flow_logs_retention_in_days
  flow_logs_s3_arn            = local.flow_logs_s3_arn
  flow_logs_s3_key_prefix     = var.vpc_flow_logs_s3_key_prefix

  tags = var.tags
}
