variable "template_name" {
  type    = string
  default = "terraform_template"
}

variable "ami" {
  type    = string
  default = "ami-0568936c8d2b91c4e"
}

variable "instance_types" {
  type    = list(any)
  default = []
}

variable "key" {
  type    = string
  default = "docker-aws-s3"
}

variable "sg_id" {
  type    = string
  default = "sg-b119b1f9"
}
