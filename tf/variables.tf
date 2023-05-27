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

variable "polly_bot_version" {
  description = "Version of polly_bot to use"
  type        = string
  # see https://github.com/CobyPear/polly_bot/releases for releases
  default = "pre-release.3"
}

# for the following values, you will need to set up an app on Discord
# see https://discord.com/developers/docs/getting-started#step-1-creating-an-app for more info
variable "DISCORD_TOKEN" {
  description = "Your discord bot token"
  type        = string
}

variable "DISCORD_CLIENT_ID" {
  description = "Your discord client id"
  type        = string
}

variable "DISCORD_SECRET" {
  description = "Your discord secret"
  type        = string
}
