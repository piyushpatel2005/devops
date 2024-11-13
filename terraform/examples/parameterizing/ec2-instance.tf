# Create a instance
resource "aws_instance" "bastion" {
  ami           = "ami-01a6e31ac994bbc09"
  instance_type = "t2.micro"
}