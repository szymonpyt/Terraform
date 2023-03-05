variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  type    = list(any)
  default = []
}

variable "vpc_cidr"{
  type    = string
  default = "172.30.0.0/21"
}

variable "public_cidr" {
  type    = string
  default = "172.30.4.0/23"
}

variable "private_cidr" {
  type    = string
  default = "172.30.2.0/23"
}

variable "ami" {
  type    = map(string)
  default = {
    us-east-1 = "ami-03dd1011b2501fbfd"
  }
}

