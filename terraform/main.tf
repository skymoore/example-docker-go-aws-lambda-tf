// terraform backend configuration
terraform {
  backend "s3" {
    // NOTE: bucket needs to be created
    bucket         = "SOME_BUCKET"
    encrypt        = true
    key            = "environments/sky-test/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tflock"
    profile        = "SOME_PROFILE"
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "SOME_PROFILE"
}

module "test_go_lambda" {
  source = "./modules/test-go-lambda"
  tags = {
    Component = "sky-testing"
  }
}