# Define variables
variable "aws_access_key" {
  type = string
}
variable "aws_secret_key" {
  type = string
}
variable "region" {
  type = string
   default = "eu-west-1"
}
variable "aws-ami" {
  type = map
  default = {
     eu-west-2 = "ami-01a6e31ac994bbc09"
     eu-west-1 = "ami-0ea3405d2d2522162"
  }
}