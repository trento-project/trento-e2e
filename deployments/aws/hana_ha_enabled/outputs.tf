output "trento_server_ip" {
  value = module.trento_server.trento_server_ip
}

output "trento_server_public_ip" {
  value = module.trento_server.trento_server_public_ip
}

output "hana_ip" {
  value = compact(module.hana_node.hana_ip)
}

output "hana_public_ip" {
  value = compact(module.hana_node.hana_public_ip)
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

