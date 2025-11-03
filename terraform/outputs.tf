output "application_url" {
  description = "URL para acessar a aplicação"
  value       = "http://localhost:${var.nginx_port}"
}

output "database_connection" {
  description = "Detalhes da conexão do banco de dados"
  value = {
    host     = docker_container.postgres.hostname
    port     = 5432
    database = var.db_name
    username = var.db_username
  }
  sensitive = true
}

output "services_status" {
  description = "Status dos serviços implantados"
  value = {
    nginx    = docker_container.nginx.must_run == true ? "running" : "stopped"
    frontend = docker_container.frontend.must_run == true ? "running" : "stopped"
    backend  = docker_container.backend.must_run == true ? "running" : "stopped"
    postgres = docker_container.postgres.must_run == true ? "running" : "stopped"
  }
}

output "networks" {
  description = "Redes Docker criadas"
  value = {
    frontend = docker_network.frontend_network.name
    backend  = docker_network.backend_network.name
  }
}

output "containers_info" {
  description = "Informações dos containers"
  value = {
    nginx    = "docker logs ${docker_container.nginx.name}"
    backend  = "docker logs ${docker_container.backend.name}"
    postgres = "docker logs ${docker_container.postgres.name}"
    frontend = "docker logs ${docker_container.frontend.name}"
  }
}

output "containers_details" {
  description = "Detalhes dos containers"
  value = {
    nginx = {
      name = docker_container.nginx.name
      image = docker_container.nginx.image
      networks = docker_container.nginx.network_data[*].network_name
    }
    backend = {
      name = docker_container.backend.name
      image = docker_container.backend.image
      networks = docker_container.backend.network_data[*].network_name
    }
    frontend = {
      name = docker_container.frontend.name
      image = docker_container.frontend.image
      networks = docker_container.frontend.network_data[*].network_name
    }
    postgres = {
      name = docker_container.postgres.name
      image = docker_container.postgres.image
      networks = docker_container.postgres.network_data[*].network_name
    }
  }
}
