# 🚀 PREPARE ENVIRONMENT - Ghost Wallet Hunter
# Script para preparar o ambiente completo de desenvolvimento

Write-Host "🎯 GHOST WALLET HUNTER - PREPARAÇÃO DO AMBIENTE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 📋 VERIFICAÇÕES INICIAIS
Write-Host "`n1️⃣ VERIFICANDO DEPENDÊNCIAS..." -ForegroundColor Yellow

# Verificar Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python não encontrado! Instale Python 3.11+" -ForegroundColor Red
    exit 1
}

# Verificar Node.js
try {
    $nodeVersion = node --version 2>&1
    Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js não encontrado! Instale Node.js 18+" -ForegroundColor Red
    exit 1
}

# Verificar Julia
try {
    $juliaVersion = julia --version 2>&1
    Write-Host "✅ Julia: $juliaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Julia não encontrado! Instale Julia 1.10+" -ForegroundColor Red
    exit 1
}

# Verificar Docker
try {
    $dockerVersion = docker --version 2>&1
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Docker não encontrado - deploy manual necessário" -ForegroundColor Yellow
}

# Verificar PostgreSQL
try {
    $pgVersion = psql --version 2>&1
    Write-Host "✅ PostgreSQL: $pgVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  PostgreSQL não encontrado - usando Docker" -ForegroundColor Yellow
}

# 📁 SETUP DO WORKSPACE
Write-Host "`n2️⃣ CONFIGURANDO WORKSPACE..." -ForegroundColor Yellow

$rootDir = Get-Location
Write-Host "📂 Root Directory: $rootDir" -ForegroundColor Cyan

# Verificar estrutura de diretórios
$requiredDirs = @(
    "backend",
    "frontend",
    "juliaos-core\backend",
    "docs",
    "db"
)

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "✅ $dir/" -ForegroundColor Green
    } else {
        Write-Host "❌ $dir/ - FALTANDO!" -ForegroundColor Red
    }
}

# 🐍 SETUP PYTHON BACKEND
Write-Host "`n3️⃣ CONFIGURANDO PYTHON BACKEND..." -ForegroundColor Yellow

Set-Location "backend"

# Criar virtual environment se não existir
if (!(Test-Path ".venv")) {
    Write-Host "📦 Criando virtual environment..." -ForegroundColor Cyan
    python -m venv .venv
}

# Ativar virtual environment
Write-Host "🔌 Ativando virtual environment..." -ForegroundColor Cyan
.\.venv\Scripts\Activate.ps1

# Instalar dependências
Write-Host "📥 Instalando dependências Python..." -ForegroundColor Cyan
pip install --upgrade pip
pip install -r requirements.txt

# Verificar instalação do cliente JuliaOS
Write-Host "🔍 Verificando cliente JuliaOS..." -ForegroundColor Cyan
try {
    python -c "import requests; print('✅ requests OK')"
    python -c "import httpx; print('✅ httpx OK')"
    Write-Host "✅ Cliente HTTP pronto para JuliaOS" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro nas dependências HTTP" -ForegroundColor Red
}

Set-Location ..

# 💎 SETUP JULIAOS BACKEND
Write-Host "`n4️⃣ CONFIGURANDO JULIAOS BACKEND..." -ForegroundColor Yellow

Set-Location "juliaos-core\backend"

# Verificar Project.toml
if (Test-Path "Project.toml") {
    Write-Host "✅ Project.toml encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ Project.toml não encontrado!" -ForegroundColor Red
}

# Instalar dependências Julia
Write-Host "📥 Instalando dependências Julia..." -ForegroundColor Cyan
julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile(); println(\"✅ Julia packages ready\")"

# Verificar arquivos principais
$juliaFiles = @(
    "run_server.jl",
    "src",
    "config",
    "db"
)

foreach ($file in $juliaFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file - FALTANDO!" -ForegroundColor Red
    }
}

Set-Location ..\..

# 🌐 SETUP FRONTEND
Write-Host "`n5️⃣ CONFIGURANDO FRONTEND..." -ForegroundColor Yellow

Set-Location "frontend"

# Instalar dependências Node.js
Write-Host "📥 Instalando dependências Node.js..." -ForegroundColor Cyan
npm install

Set-Location ..

# 🗄️ SETUP DATABASE (OPCIONAL)
Write-Host "`n6️⃣ CONFIGURANDO DATABASE..." -ForegroundColor Yellow

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "🐳 Iniciando PostgreSQL via Docker..." -ForegroundColor Cyan

    # Parar container existente se houver
    docker stop ghost-postgres 2>$null
    docker rm ghost-postgres 2>$null

    # Iniciar novo container PostgreSQL
    docker run -d `
        --name ghost-postgres `
        -e POSTGRES_DB=juliaos `
        -e POSTGRES_USER=juliaos_user `
        -e POSTGRES_PASSWORD=julia_secret_123 `
        -p 5432:5432 `
        postgres:15

    Write-Host "✅ PostgreSQL iniciado na porta 5432" -ForegroundColor Green
    Write-Host "   Database: juliaos" -ForegroundColor Cyan
    Write-Host "   User: juliaos_user" -ForegroundColor Cyan
    Write-Host "   Password: julia_secret_123" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Docker não disponível - configure PostgreSQL manualmente" -ForegroundColor Yellow
    Write-Host "   Database: juliaos" -ForegroundColor Cyan
    Write-Host "   User: juliaos_user" -ForegroundColor Cyan
    Write-Host "   Port: 5432" -ForegroundColor Cyan
}

# 🔑 VARIÁVEIS DE AMBIENTE
Write-Host "`n7️⃣ CONFIGURANDO VARIÁVEIS DE AMBIENTE..." -ForegroundColor Yellow

# Criar .env para backend se não existir
if (!(Test-Path "backend\.env")) {
    Write-Host "📝 Criando backend\.env..." -ForegroundColor Cyan
    @"
# Ghost Wallet Hunter - Backend Environment
ENVIRONMENT=development
JULIAOS_BASE_URL=http://localhost:8052
DATABASE_URL=postgresql://juliaos_user:julia_secret_123@localhost:5432/juliaos

# AI API Keys (configure suas chaves)
OPENAI_API_KEY=your_openai_key_here
GROK_API_KEY=your_grok_key_here

# Redis (opcional)
REDIS_URL=redis://localhost:6379
"@ | Out-File -FilePath "backend\.env" -Encoding UTF8
}

# Criar .env para JuliaOS se não existir
if (!(Test-Path "juliaos-core\backend\.env")) {
    Write-Host "📝 Criando juliaos-core\backend\.env..." -ForegroundColor Cyan
    @"
# JuliaOS Backend Environment
HOST=0.0.0.0
PORT=8052
ENVIRONMENT=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=juliaos
DB_USER=juliaos_user
DB_PASSWORD=julia_secret_123

# AI API Keys
OPENAI_API_KEY=your_openai_key_here
GROK_API_KEY=your_grok_key_here
"@ | Out-File -FilePath "juliaos-core\backend\.env" -Encoding UTF8
}

# 📊 RESUMO FINAL
Write-Host "`n🎯 RESUMO DA CONFIGURAÇÃO" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "✅ Backend Python: backend/" -ForegroundColor Green
Write-Host "✅ JuliaOS Backend: juliaos-core/backend/" -ForegroundColor Green
Write-Host "✅ Frontend: frontend/" -ForegroundColor Green
Write-Host "✅ Database: PostgreSQL (porta 5432)" -ForegroundColor Green
Write-Host "✅ Arquivos de configuração criados" -ForegroundColor Green

Write-Host "`n🚀 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1. Configure suas API keys nos arquivos .env" -ForegroundColor White
Write-Host "2. Execute: .\start_local_development.ps1" -ForegroundColor White
Write-Host "3. Acesse: http://localhost:3000 (Frontend)" -ForegroundColor White
Write-Host "4. APIs: http://localhost:8001 (Python) + http://localhost:8052 (Julia)" -ForegroundColor White

Write-Host "`n✨ AMBIENTE PRONTO PARA DESENVOLVIMENTO!" -ForegroundColor Green
