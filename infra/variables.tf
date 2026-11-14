variable "project" {
  description = "Nom du projet, utilise pour nommer les ressources"
  type        = string
  default     = "securecloud-pme"
}

variable "region" {
  description = "Region AWS (le Learner Lab autorise us-east-1 et us-west-2)"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Les deux zones de disponibilite utilisees"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "app_port" {
  description = "Port sur lequel ecoute le conteneur de l'application"
  type        = number
  default     = 5000
}
