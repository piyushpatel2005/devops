resource "aws_instance" "MyFirstInstance" {
    ami = "ami-05692172625678b4e"
    instance_type = "t2.micro"
}