data "aws_instance" "app" {
  instance_id = aws_instance.app.id
}

output "app_ip" {
  value = data.aws_instance.app.private_ip
}

output "app_public_ip" {
  value = data.aws_instance.app.public_ip
}
