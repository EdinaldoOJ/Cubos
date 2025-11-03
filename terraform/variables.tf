variable "project_name" {
  description = "Nome do projeto para prefixar recursos"
  type        = string
  default     = "devops-challenge"
}

variable "environment" {
  description = "Ambiente de deploy (local, dev, prod)"
  type        = string
  default     = "local"
}

variable "image_tag" {
  description = "Tag para as imagens Docker"
  type        = string
  default     = "latest"
}

variable "nginx_port" {
  description = "Porta externa para o Nginx"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Porta interna do backend"
  type        = number
  default     = 3001
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "devops_challenge"
}
