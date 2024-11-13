resource "aws_key_pair"  "devops_key" {
   key_name = "foo"
   public_key = "${file("${var.devops_public_key}")}"
}
# Create a instance
resource "aws_instance" "nginx" {
  ami           = "${lookup(var.aws-ami, var.region)}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.devops_key.key_name}"

  provisioner  "file" {
      source       = "script.sh"
      destination  = "/tmp/script.sh"
  }

  provisioner  "remote-exec" {
      inline       = [
         " chmod +x /tmp/script.sh" ,
         " sudo /tmp/script.sh"
      ]
  }
  connection {
      host = self.public_ip
      user = "${var.username}"
      private_key = "${file("${var.devops_private_key}")}"
  }
}