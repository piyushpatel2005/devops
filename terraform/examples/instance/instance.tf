# Configure AWS provider
provider "aws" {
  version = "~> 2.0"
  region = "eu-west-2"
}

# Create an instance
resource "aws_instance" "bastion" {
  ami           = "ami-01a6e31ac994bbc09"
  instnace_type = "t2.micro"
}