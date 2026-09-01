variable "region" {
  type    = string
  default = "us-gov-west-1"
}

variable "name_prefix" {
  type    = string
  default = "mountport-dsd"
}

variable "vpc_name" {
  type    = string
  default = "mountport-core"
}

variable "application_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.16.0/20"]
}

variable "broker_count" {
  type    = number
  default = 3
}

variable "broker_instance_type" {
  type    = string
  default = "kafka.m5.large"
}

variable "broker_storage_gb" {
  type    = number
  default = 200
}

variable "database_instance_class" {
  type    = string
  default = "db.m6g.large"
}

variable "database_storage_gb" {
  type    = number
  default = 100
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "image_tag" {
  type = string
}
