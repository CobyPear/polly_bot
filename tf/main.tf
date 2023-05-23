terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# key pair used to ssh in to the ec2 instance
resource "aws_key_pair" "deployer" {
  key_name   = "aws_keypair"
  public_key = file("~/.ssh/aws_keypair.pub")
}

# an ec2 instance to deploy the discord bot to
resource "aws_instance" "app_server" {
  instance_type = "t2.micro"
  # ubuntu server
  ami = "ami-053b0d53c279acc90"
  ebs_block_device {
    device_name = "ec2-storage"
    volume_size = 1
    throughput = 125
  }

  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "PollyBot"
  }
}


# bucket to store the mp3s from polly bot
resource "aws_s3_bucket" "polly_bucket" {
  bucket = "polly-bot-mp3s"

  tags = {
    Name = "PollyBot"
  }
}

# make the bucket private
resource "aws_s3_bucket_ownership_controls" "polly_bucket" {
  bucket = aws_s3_bucket.polly_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "polly_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.polly_bucket]

  bucket = aws_s3_bucket.polly_bucket.id
  acl    = "private"
}