# Define variables
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "region" {
  type = string
   default = "eu-west-2"
}
variable "aws-ami" {
  type = map
  default = {
     eu-west-2 = "ami-01a6e31ac994bbc09"
     eu-west-1 = "ami-0ea3405d2d2522162"
  }
}

variable "devops_private_key" {
  type = string
  default = "foo"

}
variable "devops_public_key" {
  type = string
  default = "foo.pub"

}
variable "username" {
  type = string
  default = "ec2-user"

}