terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # Vagy ahol tegnap építkeztél
  # NINCS profile = "..." sor!
}

resource "aws_vpc" "elso_halozatom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Jenkins-VPC-Projekt"
  }
}
