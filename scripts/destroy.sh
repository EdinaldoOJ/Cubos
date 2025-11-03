#!/bin/bash

set -e

# Configurar paths absolutos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$ROOT_DIR/terraform"

echo "Diretório Terraform: $TERRAFORM_DIR"

# Verificar se diretório terraform existe
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Pasta terraform não encontrada em: $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"
echo "Entrando no diretório: $(pwd)"

# Verificar se existem recursos para destruir
if ! terraform state list > /dev/null 2>&1; then
    echo "Nenhum recurso Terraform encontrado. Nada para destruir."
    exit 0
fi

echo "Recursos que serão destruídos:"
terraform state list

echo ""
read -p "Tem certeza que deseja destruir o ambiente? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo "Destruindo recursos..."
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo "Ambiente removido com sucesso!"
    
    # Limpar volumes orphaned (se houver)
    echo ""
    echo "Limpando volumes não utilizados..."
    docker volume prune -f
    
    # Limpar networks orphaned (se houver)
    echo "Limpando redes não utilizadas..."
    docker network prune -f
    
else
    echo "Falha ao remover ambiente"
    exit 1
fi
