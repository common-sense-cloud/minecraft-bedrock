variable "bucket-name" {
  type = string
}

variable "object-name" {
  type = string
}

variable "function-path" {
  type = string
}

variable "function-name" {
  type = string
}

variable "runtime" {
  type    = string
  default = "nodejs16"
}

variable "entry-point" {
  type        = string
  description = "Name of the function to call"
}

variable "function-description" {
  type = string
}