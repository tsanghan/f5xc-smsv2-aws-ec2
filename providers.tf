##################################################################################
# PROVIDERS
##################################################################################
terraform {
  required_version = ">= 1.16.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61.0, < 7.0.0"
    }
    # volterra = {
    #   source  = "volterraedge/volterra"
    #   version = ">= 0.12.2, < 1.0.0"
    # }
    f5xc = {
      source  = "F5Networks/f5xc"
      version = ">=0.9.5, < 1.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.6.1, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0, < 4.0.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.4.0, < 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14.1, < 1.0.0"
    }
  }
}

# provider "volterra" {
#   timeout = "90s"
#   url     = "https://training.console.ves.volterra.io/api"
# }

provider "f5xc" {
  api_token = local.f5xc_api_token
  url = "https://training-dev.console.ves.volterra.io/api"
  throttling = {}
}

provider "aws" {
  region = local.region
}

provider "http" {}

provider "random" {}

provider "cloudinit" {}
