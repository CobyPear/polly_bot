variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "path to AWS keypair public key"
  type        = string
  default     = "~/.ssh/aws_keypair.pub"
}

variable "bucket_name" {
  description = "name of S3 bucket"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile to use with the ec2 instance. Must have permissions for s3, and polly."
  type        = string
  default     = "PollyBotEC2"
}