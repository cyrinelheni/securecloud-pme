# ---------------------------------------------------------------
# Groupes de securite : le pare-feu de chaque niveau.
# Chaque niveau n'accepte que le trafic du niveau juste au-dessus.
#   CloudFront --80--> ALB --5000--> application --5432--> base
# ---------------------------------------------------------------

# Liste des adresses IP de CloudFront, maintenue par AWS
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "ALB : accepte uniquement le trafic venant de CloudFront"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-alb-sg" }

  #checkov:skip=CKV2_AWS_5:Groupe rattache a sa ressource aux etapes 6 et 7
}

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "Application : accepte uniquement le trafic venant de l ALB"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-app-sg" }

  #checkov:skip=CKV2_AWS_5:Groupe rattache a sa ressource aux etapes 6 et 7
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "Base de donnees : accepte uniquement le trafic venant de l application"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-db-sg" }

  #checkov:skip=CKV2_AWS_5:Groupe rattache a sa ressource aux etapes 6 et 7
}

# --- ALB ---
resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP depuis CloudFront uniquement"

  #checkov:skip=CKV_AWS_260:Faux positif - la source est la liste d'adresses CloudFront, pas 0.0.0.0/0
  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol    = "tcp"
  from_port      = 80
  to_port        = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Vers les conteneurs de l application"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# --- Application ---
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Depuis l ALB uniquement"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Vers la base PostgreSQL"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "app_to_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS sortant (ECR, Secrets Manager, CloudWatch) via la NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# --- Base de donnees ---
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL depuis l application uniquement"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
# Aucune regle sortante pour la base : elle ne peut contacter personne.
