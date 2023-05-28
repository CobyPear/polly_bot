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
  region = var.aws_region
}

# key pair used to ssh in to the ec2 instance
resource "aws_key_pair" "deployer" {
  key_name   = "polly_bot_keypair"
  public_key = file(var.public_key)
}

# an ec2 instance to deploy the discord bot to
resource "aws_instance" "app_server" {
  instance_type = "t3.nano"
  # aws linux
  ami                  = "ami-0715c1897453cabd1"
  key_name             = aws_key_pair.deployer.key_name
  iam_instance_profile = aws_iam_instance_profile.polly_bot_instance_profile.name
  root_block_device {
    delete_on_termination = true
  }
  # init script downloads source code and starts the service via systemd
  user_data = templatefile("${path.module}/init.tftpl", {
    polly_bot_version = var.polly_bot_version,
    region            = var.aws_region,
    bucket_name       = var.bucket_name
  })

  tags = {
    Name = "PollyBot"
  }
}

# Parameter Storage for discord secrets
resource "aws_kms_key" "kms_key" {
  description = "KMS key 1"
}

resource "aws_kms_key_policy" "key_policy" {
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode({
    Id = "kms_key"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }

        Resource = "*"
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_ssm_parameter" "DISCORD_TOKEN" {
  name   = "DISCORD_TOKEN"
  value  = var.DISCORD_TOKEN
  type   = "SecureString"
  key_id = aws_kms_key.kms_key.id
}

# IAM roles and policy docs

# IAM role for the instance profile
resource "aws_iam_role" "role" {
  name               = "polly_bot_iam_role_ec2"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# attach role to an instance profile for use witht he ec2 instance
resource "aws_iam_instance_profile" "polly_bot_instance_profile" {
  name = "polly_bot_iam_profile_ec2"
  role = aws_iam_role.role.name
  tags = {
    Name = "PollyBot"
  }
}

# policy made from policy doc
resource "aws_iam_policy" "policy" {
  name        = "polly_bot_policy"
  description = "Policy for polly_bot"
  policy      = data.aws_iam_policy_document.policy_doc.json
}

# attach policy doc to role
resource "aws_iam_role_policy_attachment" "attach_policy_doc" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

# ec2 role
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = 1
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# policy doc for polly and s3 access
data "aws_iam_policy_document" "policy_doc" {
  #s3 access
  statement {
    actions = [
      "s3:*",
      "s3-object-lambda:*"
    ]
    resources = ["*"]
  }
  # polly access
  statement {
    actions   = ["polly:*"]
    resources = ["*"]
  }
}


# bucket to store the mp3s from polly bot
resource "aws_s3_bucket" "polly_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
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
