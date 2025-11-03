# 🚀 Desafio DevOps (Sistema operacional usado -> Linux)

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Estrutura do Projeto](#estrutura-do-projeto)
4. [Alterações Realizadas](#alterações-realizadas)
5. [Tutorial Passo a Passo](#tutorial-passo-a-passo)
6. [Comandos Úteis](#comandos-úteis)
7. [Solução de Problemas](#solução-de-problemas)

---

## 🎯 Visão Geral

Este projeto implementa uma infraestrutura completa usando **Docker** e **Terraform** no sistema operacional **Linux** com:
- **Frontend**: Página HTML estática servida por Nginx
- **Backend**: API Node.js que se conecta ao banco de dados
- **Banco de Dados**: PostgreSQL com dados iniciais
- **Proxy Reverso**: Nginx para roteamento de tráfego

---

## ⚙️ Pré-requisitos

### 🛠️ Software Necessário

1. **Docker** - Para containerização
   ```bash
   # No Ubuntu/Debian:
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   # Reinicie o terminal após executar
   ```

2. **Terraform** - Para infraestrutura como código
   ```bash
   # No Ubuntu/Debian:
   sudo apt update && sudo apt install -y gnupg software-properties-common curl
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install -y terraform
   ```

---

## 📁 Estrutura do Projeto

```
desafio-devops/
├── 📂 terraform/               # Infraestrutura como código
│   ├── main.tf                # Configuração principal
│   ├── variables.tf           # Variáveis do projeto
│   ├── outputs.tf            # Saídas do Terraform
│   └── terraform.tfvars      # Valores das variáveis
├── 📂 scripts/                # Scripts de automação
│   ├── init.sh               # Inicializa todo o ambiente
│   ├── destroy.sh            # Remove todo o ambiente
│   └── healthcheck.sh        # Verifica saúde dos serviços
├── 📂 backend/                # Aplicação Node.js
│   ├── Dockerfile            # Containerização do backend
│   ├── index.js              # Código principal (API)
│   └── package.json          # Dependências Node.js
├── 📂 frontend/               # Aplicação Frontend
│   ├── Dockerfile            # Containerização do frontend
│   └── index.html            # Página web
├── 📂 nginx/                  # Proxy Reverso
│   └── nginx.conf            # Configuração do Nginx
├── 📂 sql/               # Banco de dados
│   └── script.sql              # Script de inicialização do DB
└── 📄 README.md              # Esta documentação
```

---

## 🔧 Alterações Realizadas

### 1. 🔄 **Backend - Correções Principais**

**Problema Original:**
```javascript
// CÓDIGO PROBLEMÁTICO ORIGINAL
const client = new PG.Client(
  `postgres://${user}:${pass}@${host}:${db_port}`  // Variáveis não definidas!
);
```

**Solução Implementada:**
```javascript
// CÓDIGO CORRIGIDO
const client = new Client({
  host: process.env.DB_HOST,      // Variáveis de ambiente
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});
```

**Melhorias Adicionadas:**
- ✅ **Conexão com Retry Automático** (até 10 tentativas)
- ✅ **Novo cliente PostgreSQL** para cada tentativa (evita reutilização)
- ✅ **Health Checks** para monitoramento
- ✅ **Graceful Shutdown** para desligamento seguro
- ✅ **Tratamento Robusto de Erros** com reconexão automática
- ✅ **Verificação de Tabelas** antes de executar queries
- ✅ **Logs Detalhados** para debugging

### 2. 🌐 **Frontend - Correções**

**Problema Original:**
```javascript
// CÓDIGO PROBLEMÁTICO
const result = await fetch("/api", { mode: 'no-cors' })
```

**Solução Implementada:**
```javascript
// CÓDIGO CORRIGIDO
const response = await fetch("/api");
const result = await response.json();
```

**Melhorias:**
- ✅ Removido `no-cors` que impedia leitura da resposta
- ✅ Adicionado tratamento de erro com try/catch
- ✅ Mensagens de erro visíveis para o usuário

### 3. 🛠️ **Scripts de Automação**

**Novos Scripts Criados:**

| Script | Finalidade |
|--------|------------|
| `init.sh` | Implanta ambiente completo |
| `destroy.sh` | Remove ambiente completamente |
| `healthcheck.sh` | Verifica saúde dos serviços |

---

## 🚀 Tutorial Passo a Passo

### 📥 Passo 1: Baixar o Projeto

```bash
# Clone o repositório (substitua pela URL real)
git clone https://github.com/seu-usuario/desafio-devops.git
cd Cubos

# Ou se você já tem os arquivos, apenas acesse a pasta
cd Cubos
```

### 🏗️ Passo 2: Executar a Implantação

```bash
# Torne os scripts executáveis (apenas primeira vez)
chmod +x scripts/*.sh

# Execute o script de inicialização
./scripts/init.sh
```

**O que acontece:**
1. ✅ Verifica Docker e Terraform
2. ✅ Inicializa Terraform
3. ✅ Valida configuração
4. ✅ Cria redes Docker
5. ✅ Constrói imagens
6. ✅ Sobe containers
7. ✅ Executa health checks

### 🌐 Passo 4: Testar a Aplicação

**Método 1 - Navegador:**
```
Abra: http://localhost
```

**Método 2 - Terminal:**
```bash
# Testar API diretamente
curl http://localhost/api

# Verificar saúde
./scripts/healthcheck.sh
```

### 🛑 Passo 5: Parar o Ambiente (Quando Finalizar)

```bash
# Parar e remover tudo
./scripts/destroy.sh
```

---

## 🎯 Comandos Úteis

### 🐳 Comandos Docker

```bash
# Ver todos os containers
docker ps -a

# Ver logs do backend
docker logs desafio-backend-local 

# Ver logs do banco
docker logs desafio-postgres-local

# Ver redes
docker network ls

# Ver imagens
docker images
```

---

**Desenvolvido com ❤️ para o Desafio DevOps**
