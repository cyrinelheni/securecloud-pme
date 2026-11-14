# ---------------------------------------------------------------
# VPC : le reseau prive du projet dans AWS
# ---------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  #checkov:skip=CKV2_AWS_11:Les VPC Flow Logs seront ajoutes a l'etape 9 (supervision)

  tags = { Name = "${var.project}-vpc" }
}

# Le groupe de securite par defaut du VPC est vide :
# aucune ressource ne peut l'utiliser pour communiquer par accident.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-default-sg-ferme" }
}

# Porte d'entree / sortie vers Internet, unique pour tout le VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}

# ---------------------------------------------------------------
# Sous-reseaux : 3 niveaux x 2 zones de disponibilite
# ---------------------------------------------------------------

# Niveau 1 - public : ALB et NAT Gateway
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index + 1) # 10.0.1.0/24 et 10.0.2.0/24
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = { Name = "${var.project}-public-${count.index + 1}", Tier = "public" }
}

# Niveau 2 - prive : conteneurs de l'application (ECS Fargate)
resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 11) # 10.0.11.0/24 et 10.0.12.0/24
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project}-app-${count.index + 1}", Tier = "app" }
}

# Niveau 3 - prive : base de donnees (RDS)
resource "aws_subnet" "data" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 21) # 10.0.21.0/24 et 10.0.22.0/24
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project}-data-${count.index + 1}", Tier = "data" }
}

# ---------------------------------------------------------------
# Tables de routage : qui peut aller ou
# ---------------------------------------------------------------

# Public : sortie vers Internet par l'Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Application : pas encore de sortie Internet.
# La route vers la NAT Gateway sera ajoutee a l'etape 7.
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-rt-app" }
}

resource "aws_route_table_association" "app" {
  count          = 2
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

# Donnees : aucune route vers Internet, ni maintenant ni plus tard
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-rt-data" }
}

resource "aws_route_table_association" "data" {
  count          = 2
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}
