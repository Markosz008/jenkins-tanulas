terraform {
  # Ez a blokk mondja meg a Terraformnak, hogy NE helyben tárolja a state-et
  backend "s3" {
    bucket         = "markosz-jenkins-terraform-state" # Ide írd a saját bucketed nevét!
    key            = "projektek/jenkins-vpc/terraform.tfstate"     # A fájl elérési útja a bucketben
    region         = "eu-central-1"
    encrypt        = true                              # Biztonság kedvéért titkosítjuk
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "elso_halozatom" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Jenkins-VPC-Projekt"
  }
}
