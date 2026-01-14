variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Préfixe des ressources"
  type        = string
  default     = "devops-platform"
}

variable "public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_type" {
  description = "Type d'instance pour Jenkins/Sonar/Nexus/master"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Type d'instance pour les workers K8s"
  type        = string
  default     = "t3.large"
}

variable "workers_count" {
  description = "Nombre de workers Kubernetes"
  type        = number
  default     = 2
}

variable "preprod_state" {
  description = "Etat des instances de préproduction (running ou stopped)"
  type        = string
  default     = "stopped"
}
