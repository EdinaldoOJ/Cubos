terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Redes Docker
resource "docker_network" "frontend_network" {
  name   = "${var.project_name}-frontend-${var.environment}"
  driver = "bridge"
  
  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
}

resource "docker_network" "backend_network" {
  name   = "${var.project_name}-backend-${var.environment}"
  driver = "bridge"
  
  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  internal = true
}

# Volume para PostgreSQL
resource "docker_volume" "postgres_data" {
  name = "${var.project_name}-postgres-data-${var.environment}"
}

# Build da imagem do Backend
resource "docker_image" "backend" {
  name = "${var.project_name}-backend:${var.image_tag}"
  
  build {
    context = "../backend"
    tag     = ["${var.project_name}-backend:latest"]
  }
  
  triggers = {
    dir_sha1 = sha1(join("", [
      filesha1("../backend/Dockerfile"),
      filesha1("../backend/index.js"),
      filesha1("../backend/package.json")
    ]))
  }
}

# Build da imagem do Frontend
resource "docker_image" "frontend" {
  name = "${var.project_name}-frontend:${var.image_tag}"
  
  build {
    context = "../frontend"
    tag     = ["${var.project_name}-frontend:latest"]
  }
  
  triggers = {
    dir_sha1 = sha1(join("", [
      filesha1("../frontend/Dockerfile"),
      filesha1("../frontend/index.html")
    ]))
  }
}

# Imagem do Nginx
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Imagem do PostgreSQL
resource "docker_image" "postgres" {
  name         = "postgres:15.8"
  keep_locally = true
}

# Container do PostgreSQL
resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres-${var.environment}"
  image = docker_image.postgres.image_id
  hostname = "postgres"

  env = [
    "POSTGRES_USER=${var.db_username}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_INITDB_ARGS=--encoding=UTF8 --locale=C"
  ]

  networks_advanced {
    name = docker_network.backend_network.name
  }

  volumes {
    host_path      = abspath("../sql/script.sql")
    container_path = "/docker-entrypoint-initdb.d/script.sql"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  restart = "unless-stopped"
  
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_username} -d ${var.db_name}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
    start_period = "30s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "database"
  }

  depends_on = [
    docker_volume.postgres_data
  ]
}

# Container do Backend
resource "docker_container" "backend" {
  name  = "${var.project_name}-backend-${var.environment}"
  image = docker_image.backend.image_id
  hostname = "backend"

  env = [
    "PORT=${var.backend_port}",
    "DB_HOST=${docker_container.postgres.hostname}",
    "DB_PORT=5432",
    "DB_USER=${var.db_username}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=${var.db_name}"
  ]

  networks_advanced {
    name = docker_network.frontend_network.name
  }
  
  networks_advanced {
    name = docker_network.backend_network.name
  }

  restart = "unless-stopped"
  
  healthcheck {
    test     = ["CMD-SHELL", "curl -f http://localhost:${var.backend_port}/api || exit 1"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
    start_period = "30s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "backend"
  }

  depends_on = [
    docker_container.postgres
  ]
}

# Container do Frontend
resource "docker_container" "frontend" {
  name  = "${var.project_name}-frontend-${var.environment}"
  image = docker_image.frontend.image_id
  hostname = "frontend"

  networks_advanced {
    name = docker_network.frontend_network.name
  }

  restart = "unless-stopped"

  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "frontend"
  }
}

# Container do Nginx (Proxy Reverso)
resource "docker_container" "nginx" {
  name  = "${var.project_name}-nginx-${var.environment}"
  image = docker_image.nginx.image_id
  hostname = "nginx"

  ports {
    internal = 80
    external = var.nginx_port
  }

  networks_advanced {
    name = docker_network.frontend_network.name
  }

  volumes {
    host_path      = abspath("../nginx/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  restart = "unless-stopped"
  
  healthcheck {
    test     = ["CMD-SHELL", "curl -f http://localhost:80/ || exit 1"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
    start_period = "10s"
  }

  labels {
    label = "project"
    value = var.project_name
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "service"
    value = "nginx"
  }

  depends_on = [
    docker_container.backend,
    docker_container.frontend
  ]
}
