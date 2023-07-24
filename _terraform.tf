terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    key = "terraform.tfstate"
  }

  required_providers {
    # https://github.com/terraform-providers/terraform-provider-aws/releases
    aws = {
      source  = "hashicorp/aws"
      version = "5.8.0"
    }
    # https://github.com/terraform-providers/terraform-provider-local/releases
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "aws" {
  /*
  * The credentials used by aws configure defaults.
  * And no-use terraform specification.
  */
  #access_key =
  #secret_key =
}

provider "local" {}
