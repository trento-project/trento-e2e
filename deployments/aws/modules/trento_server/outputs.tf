data "aws_instance" "trento_server" {
  instance_id = aws_instance.trento_server.id
}

output "trento_server_ip" {
  value = data.aws_instance.trento_server.private_ip
}

output "trento_server_public_ip" {
  value = data.aws_instance.trento_server.public_ip
}