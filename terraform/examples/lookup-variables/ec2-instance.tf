# Create a instance
resource "aws_instance" "bastion" {
  ami           = "${lookup(var.aws-ami, var.region)}"
  instance_type = "t2.micro"
}