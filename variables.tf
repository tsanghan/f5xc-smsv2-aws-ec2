##################################################################################
# VARIABLES
##################################################################################

variable "student_no" {
  type    = string
  default = "1"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "public_key" {
  type = string
}

variable "key_name" {
  type    = string
  default = "f5xc-admin-smsv2"
}

variable "extra_cidrs" {
  type    = string
  default = null
}

variable "in_github_action" {
  type    = bool
  default = false
}

variable "f5xc_api_token" {
  type    = string
  default = null
}
