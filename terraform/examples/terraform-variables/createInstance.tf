resource "aws_instance" "MyFirstInstance" {
    ami = lookup(var.AMIS, var.AWS_REGION)
    instance_type = "t2.micro"
    tags = {
    Name = "demoinstance"
  }
  security_groups = "${var.Security_Group}"
}