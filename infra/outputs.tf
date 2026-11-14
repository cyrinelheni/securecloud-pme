output "vpc_id" {
  description = "Identifiant du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Sous-reseaux publics (ALB, NAT)"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Sous-reseaux prives de l'application (ECS)"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Sous-reseaux prives des donnees (RDS)"
  value       = aws_subnet.data[*].id
}

output "security_group_ids" {
  description = "Groupes de securite par niveau"
  value = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}
