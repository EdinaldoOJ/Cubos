#!/bin/bash

# Função para verificar HTTP status
check_http() {
    local url=$1
    local service=$2
    echo -n "Verificando $service... "
    
    if curl -f -s -o /dev/null --connect-timeout 5 "$url"; then
        echo "OK"
        return 0
    else
        echo "FALHA"
        return 1
    fi
}

# Verificar aplicação principal
check_http "http://localhost:80" "Aplicação Frontend"

# Verificar API
echo -n "Verificando API Backend... "
if curl -f -s "http://localhost:80/api" | grep -q "database"; then
    echo "OK"
else
    echo "FALHA"
fi