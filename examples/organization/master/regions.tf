# --------------------------------------------------------------------------------------------------
# A list of providers for all AWS regions.
# Reference: https://docs.aws.amazon.com/general/latest/gr/rande.html
# --------------------------------------------------------------------------------------------------

provider "aws" {
  region = "us-gov-west-1"
  alias  = "us-gov-west-1"
}

provider "aws" {
  region = "us-gov-east-1"
  alias  = "us-gov-east-1"
}
