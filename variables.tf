variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "az1" {
  description = "Availability Zone 1"
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "Availability Zone 2"
  type        = string
  default     = "us-east-1b"
}

variable "s3_to_cloudfront" {
  description = "s3 bucket to Cloudfront"
  type        = string
  default     = "s3-cloudfront-sange"
}

variable "container_port" {
  description = "container port"
  type        = number
  default     = 80
}