# Variables Configuration
#



variable "region-name" {
  default = "eu-west-2"
  type    = string
}

variable "cluster-name" {
  default = "tejas-tech"
  type    = string
}


variable "vpc-name" {
  default = "devops"
  type    = string
}


variable "subnet-count" {
  default = 3
}

variable "instance-type" {
  default = "t2.micro"
  type    = string
}

variable "min-instances" {
  default = 3
}

variable "max-instances" {
  default = 3
}

variable "key-pair" {
  default = "devops"
  type    = string
}