#!/bin/bash

set -e

# Configurar paths absolutos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR/terraform"

echo "Diretório raiz: $ROOT_DIR"
echo "Diretório Terraform: $TERRAFORM_DIR"

# Verificar se diretório terraform existe
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Pasta terraform não encontrada em: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"
echo "Entrando no diretório: $(pwd)"

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker não está instalado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "Docker daemon não está rodando. Por favor, inicie o Docker."
    exit 1
fi

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo "Terraform não está instalado. Por favor, instale o Terraform primeiro."
    exit 1
fi

echo "Pré-requisitos verificados: Docker e Terraform OK"

# Inicializar Terraform
echo ""
echo "Inicializando Terraform..."
terraform init

if [ $? -ne 0 ]; then
    echo "Falha na inicialização do Terraform"
    exit 1
fi

# Validar configuração
echo ""
echo "Validando configuração Terraform..."
terraform validate

# Aplicar configuração
echo ""
echo "Aplicando configuração do Terraform..."
terraform apply -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo "Ambiente implantado com sucesso!"
    echo "==================================="
    
    # Mostrar outputs
    echo ""
    echo "Status dos serviços:"
    terraform output services_status
    
    echo ""
    echo "Acesse a aplicação em: http://localhost:80"
    
    echo ""
    echo "Para parar o ambiente, execute: ./scripts/destroy.sh"
    echo ""
    echo "Para verificar a saúde da aplicação: ./scripts/healthcheck.sh"
else
    echo "Falha na implantação do ambiente"
    exit 1
fi
