# 🗄️ CONFIGURAÇÃO DO BANCO DE DADOS POSTGRESQL

## Ghost Wallet Hunter - JuliaOS Integration

---

## 📋 **SITUAÇÃO ATUAL**

O JuliaOS Backend **PRECISA** de PostgreSQL para funcionar corretamente. Existem **3 opções** configuradas:

### ✅ **OPÇÃO 1: Docker Container Simples (RECOMENDADO para desenvolvimento)**

### ✅ **OPÇÃO 2: Docker Compose (do JuliaOS)**

### ✅ **OPÇÃO 3: PostgreSQL Local (manual)**

---

## 🐳 **OPÇÃO 1: DOCKER CONTAINER SIMPLES (AUTOMÁTICO)**

### **Como funciona:**

- ✅ Scripts `prepare_environment.ps1` e `start_local_development.ps1` **JÁ CONFIGURADOS**
- ✅ Cria automaticamente container `ghost-postgres`
- ✅ Configuração compatível com `.env` do JuliaOS

### **Configuração Automática:**

```powershell
# Executado automaticamente pelos scripts
docker run -d \
    --name ghost-postgres \
    -e POSTGRES_DB=juliaos \
    -e POSTGRES_USER=juliaos_user \
    -e POSTGRES_PASSWORD=julia_secret_123 \
    -p 5432:5432 \
    postgres:15
```

### **Vantagens:**

- ✅ **Automático**: Nada para configurar manualmente
- ✅ **Compatível**: Mesmas credenciais do `.env`
- ✅ **Simples**: Um comando só
- ✅ **Limpo**: Fácil de resetar

---

## 🐳 **OPÇÃO 2: DOCKER COMPOSE (DO JULIAOS)**

### **Como funcionaa:**

- ✅ Arquivo `juliaos-core/backend/docker-compose.yml` **JÁ EXISTE**
- ✅ Configura PostgreSQL + JuliaOS Backend juntos
- ⚠️ Precisa ajustar variáveis para compatibilidade

### **Para usar esta opção:**

```powershell
# 1. Ir para o diretório JuliaOS
cd juliaos-core\backend

# 2. Iniciar com Docker Compose
docker-compose up -d julia-db

# 3. Aguardar banco inicializar
docker-compose logs julia-db

# 4. Iniciar JuliaOS Backend
julia --project=. run_server.jl
```

### **Configuração atual (`docker-compose.yml`):**

```yaml
services:
  julia-db:
    image: postgres:17
    container_name: julia-db
    environment:
      POSTGRES_USER: ${DB_USER}          # juliaos_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # julia_secret_123
      POSTGRES_DB: ${DB_NAME}           # juliaos
      PGPORT: ${DB_PORT}                # 5432
    ports:
      - "${DB_PORT}:${DB_PORT}"         # 5432:5432
    volumes:
      - ./migrations/up.sql:/docker-entrypoint-initdb.d/init.sql
```

### **Vantagenss:**

- ✅ **Oficial**: Configuração original do JuliaOS
- ✅ **Migrations**: Executa automaticamente `migrations/up.sql`
- ✅ **Health checks**: Verifica se banco está pronto
- ✅ **Logs estruturados**: Melhor debugging

---

## 💻 **OPÇÃO 3: POSTGRESQL LOCAL (MANUAL)**

a

- Instalar PostgreSQL nativo no Windows
- Configurar database e usuário manualmente
- Conectar JuliaOS ao PostgreSQL local

### **Instalação:**

```powershell
# 1. Baixar PostgreSQL
# https://www.postgresql.org/download/windows/

# 2. Instalar e configurar

# 3. Criar database
psql -U postgres
CREATE DATABASE juliaos;
CREATE USER juliaos_user WITH PASSWORD 'julia_secret_123';
GRANT ALL PRIVILEGES ON DATABASE juliaos TO juliaos_user;
```

### **Vantagensss:**

- ✅ **Performance**: Nativo, sem overhead do Docker
- ✅ **Persistente**: Dados não são perdidos
- ✅ **Ferramentas**: pgAdmin, etc.

### **Desvantagens:**

- ❌ **Complexo**: Instalação manual
- ❌ **Conflitos**: Pode conflitar com outras instâncias
- ❌ **Portabilidade**: Específico do ambiente

---

## 🎯 **RECOMENDAÇÃO: QUAL USAR?**

### 🥇 **PARA DESENVOLVIMENTO: OPÇÃO 1 (Docker Simples)**

```powershell
# APENAS EXECUTE - já está tudo configurado!
.\prepare_environment.ps1
.\start_local_development.ps1
```

**Por que?**

- ✅ **Zero configuração manual**
- ✅ **Scripts já configurados**
- ✅ **Compatível com todos os .env**
- ✅ **Fácil de resetar**: `docker rm ghost-postgres`

### 🥈 **PARA DEBUGGING AVANÇADO: OPÇÃO 2 (Docker Compose)**

```powershell
cd juliaos-core\backend
docker-compose up -d julia-db
# Depois execute os scripts normais
```

**Por que?**

- ✅ **Migrations automáticas**
- ✅ **Health checks**
- ✅ **Logs estruturados**
- ✅ **Configuração oficial do JuliaOS**

---

## 🔧 **STATUS ATUAL DAS CONFIGURAÇÕES**

### ✅ **JÁ CONFIGURADO (AUTOMÁTICO):**

#### **1. Scripts PowerShell:**

- `prepare_environment.ps1` → Cria container `ghost-postgres`
- `start_local_development.ps1` → Inicia/verifica PostgreSQL

#### **2. Arquivos .env sincronizados:**

```bash
# juliaos-core/backend/.env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=juliaos
DB_USER=juliaos_user
DB_PASSWORD=julia_secret_123
```

#### **3. Docker Compose existente:**

- `juliaos-core/backend/docker-compose.yml` → PostgreSQL 17 configurado

---

## 🚀 **TESTE RÁPIDO:**

### **Verificar se PostgreSQL está funcionando:**

```powershell
# 1. Iniciar ambiente
.\prepare_environment.ps1

# 2. Verificar container
docker ps | findstr ghost-postgres

# 3. Testar conexão
docker exec -it ghost-postgres psql -U juliaos_user -d juliaos -c "\dt"

# 4. Iniciar desenvolvimento
.\start_local_development.ps1
```

---

## ❓ **QUAL OPÇÃO VOCÊ PREFERE?**

### 🎯 **Opção Recomendada (Automática):**

```powershell
# Execute apenas isto - zero configuração manual!
.\prepare_environment.ps1
```

### 🔧 **Opção Avançada (Docker Compose):**

```powershell
cd juliaos-core\backend
docker-compose up -d julia-db
cd ..\..
.\start_local_development.ps1
```

**Qual você quer usar?** A **Opção 1 (automática)** já está 100% configurada! 🚀
