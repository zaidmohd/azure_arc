#
# Variables Configuration
#

variable "AWS_ACCESS_KEY_ID" {
  description = "Your AWS Access Key ID"
  type        = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Your AWS Secret Key"
  type        = string
}

variable "cluster-name" {
  default = "zc-aws-eks-01"
  type    = string
}
