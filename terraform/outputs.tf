output "instance_public_ip" {
  description = "L'adresse IP publique de l'instance EC2"
  value       = aws_instance.tp3_server.public_ip
}

output "instance_public_dns" {
  description = "Le DNS public de l'instance EC2"
  value       = aws_instance.tp3_server.public_dns
}
