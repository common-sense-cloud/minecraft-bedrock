variable "zone" {
  type    = string
  default = "us-east1-b"
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "project_id" {
  type    = string
  default = "terraform-basics-12"
}

variable "service-account" {
  type    = string
  default = "terraform@terraform-basics-12.iam.gserviceaccount.com"
}