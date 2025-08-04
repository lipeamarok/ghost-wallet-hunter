# 🚀 START LOCAL DEVELOPMENT - Ghost Wallet Hunter
# Script para iniciar todos os serviços em desenvolvimento

Write-Host "🎯 GHOST WALLET HUNTER - DESENVOLVIMENTO LOCAL" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

# 🔍 VERIFICAR SE O AMBIENTE FOI PREPARADO
Write-Host "`n1️⃣ VERIFICANDO AMBIENTE..." -ForegroundColor Yellow

if (!(Test-Path "backend\.venv")) {
    Write-Host "❌ Ambiente Python não preparado! Execute: .\prepare_environment.ps1" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "frontend\node_modules")) {
    Write-Host "❌ Dependências Node.js não instaladas! Execute: .\prepare_environment.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Ambiente verificado!" -ForegroundColor Green

# 🗄️ VERIFICAR/INICIAR DATABASE
Write-Host "`n2️⃣ VERIFICANDO DATABASE..." -ForegroundColor Yellow

try {
    # Verificar se PostgreSQL está rodando (Docker ou local)
    $pgStatus = docker ps --filter "name=ghost-postgres" --format "{{.Status}}" 2>$null
    if ($pgStatus -match "Up") {
        Write-Host "✅ PostgreSQL (Docker) já está rodando" -ForegroundColor Green
    }
    else {
        Write-Host "🐳 Iniciando PostgreSQL via Docker..." -ForegroundColor Cyan
        docker start ghost-postgres 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Container não existe, criar novo
            docker run -d `
                --name ghost-postgres `
                -e POSTGRES_DB=juliaos `
                -e POSTGRES_USER=juliaos_user `
                -e POSTGRES_PASSWORD=julia_secret_123 `
                -p 5432:5432 `
                postgres:15
        }
        Start-Sleep 5
        Write-Host "✅ PostgreSQL iniciado!" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Verificar PostgreSQL manualmente" -ForegroundColor Yellow
}

# 🎬 FUNÇÃO PARA INICIAR SERVIÇOS EM BACKGROUND
function Start-ServiceInBackground {
    param(
        [string]$Name,
        [string]$Command,
        [string]$WorkingDirectory = ".",
        [string]$Color = "White"
    )

    Write-Host "🚀 Iniciando $Name..." -ForegroundColor $Color

    Start-Process powershell -ArgumentList "-NoExit", "-Command", "
        Write-Host '🎯 $Name - $(Get-Date)' -ForegroundColor $Color;
        Set-Location '$WorkingDirectory';
        $Command
    " -WindowStyle Normal
}

# 💎 INICIAR JULIAOS BACKEND
Write-Host "`n3️⃣ INICIANDO JULIAOS BACKEND..." -ForegroundColor Yellow

$juliaCommand = @"
Write-Host '📡 Aguardando database...' -ForegroundColor Cyan;
Start-Sleep 3;
Write-Host '🎯 Iniciando JuliaOS Server...' -ForegroundColor Cyan;
julia --project=. run_server.jl
"@

Start-ServiceInBackground -Name "JuliaOS Backend" -Command $juliaCommand -WorkingDirectory "juliaos-core\backend" -Color "Magenta"

# Aguardar JuliaOS iniciar
Write-Host "⏳ Aguardando JuliaOS Backend inicializar..." -ForegroundColor Cyan
Start-Sleep 10

# 🐍 INICIAR PYTHON BACKEND
Write-Host "`n4️⃣ INICIANDO PYTHON BACKEND..." -ForegroundColor Yellow

$pythonCommand = @"
Write-Host '🔌 Ativando virtual environment...' -ForegroundColor Green;
.\.venv\Scripts\Activate.ps1;
Write-Host '🎯 Iniciando Python Backend...' -ForegroundColor Green;
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001
"@

Start-ServiceInBackground -Name "Python Backend" -Command $pythonCommand -WorkingDirectory "backend" -Color "Green"

# Aguardar Python Backend iniciar
Write-Host "⏳ Aguardando Python Backend inicializar..." -ForegroundColor Cyan
Start-Sleep 8

# 🌐 INICIAR FRONTEND
Write-Host "`n5️⃣ INICIANDO FRONTEND..." -ForegroundColor Yellow

$frontendCommand = @"
Write-Host '🎯 Iniciando Frontend React...' -ForegroundColor Blue;
npm run dev
"@

Start-ServiceInBackground -Name "Frontend React" -Command $frontendCommand -WorkingDirectory "frontend" -Color "Blue"

# Aguardar Frontend iniciar
Write-Host "⏳ Aguardando Frontend inicializar..." -ForegroundColor Cyan
Start-Sleep 5

# 🔍 VERIFICAR SERVIÇOS
Write-Host "`n6️⃣ VERIFICANDO SERVIÇOS..." -ForegroundColor Yellow

$services = @(
    @{Name = "JuliaOS Backend"; Url = "http://localhost:8052/health"; Color = "Magenta" },
    @{Name = "Python Backend"; Url = "http://localhost:8001/health"; Color = "Green" },
    @{Name = "Frontend"; Url = "http://localhost:3000"; Color = "Blue" }
)

foreach ($service in $services) {
    try {
        Write-Host "🔍 Testando $($service.Name)..." -ForegroundColor $service.Color
        $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $($service.Name) - OK" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  $($service.Name) - Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ $($service.Name) - Não respondendo" -ForegroundColor Red
    }
}

# 📋 INFORMAÇÕES DE ACESSO
Write-Host "`n🎯 INFORMAÇÕES DE ACESSO" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "🌐 Frontend:        http://localhost:3000" -ForegroundColor Blue
Write-Host "🐍 Python Backend:  http://localhost:8001" -ForegroundColor Green
Write-Host "💎 JuliaOS Backend: http://localhost:8052" -ForegroundColor Magenta
Write-Host "🗄️  PostgreSQL:     localhost:5432" -ForegroundColor Yellow

Write-Host "`n📚 ENDPOINTS ÚTEIS:" -ForegroundColor White
Write-Host "• http://localhost:8001/docs (Python API)" -ForegroundColor Gray
Write-Host "• http://localhost:8001/health (Python Health)" -ForegroundColor Gray
Write-Host "• http://localhost:8052/health (Julia Health)" -ForegroundColor Gray
Write-Host "• http://localhost:8052/agents (Julia Agents)" -ForegroundColor Gray

Write-Host "`n🛠️  COMANDOS ÚTEIS:" -ForegroundColor White
Write-Host "• docker logs ghost-postgres (logs do banco)" -ForegroundColor Gray
Write-Host "• Ctrl+C nas janelas para parar serviços" -ForegroundColor Gray

Write-Host "`n✨ TODOS OS SERVIÇOS INICIADOS!" -ForegroundColor Green
Write-Host "📱 Acesse http://localhost:3000 para começar" -ForegroundColor Cyan

# 🔄 AGUARDAR INTERAÇÃO DO USUÁRIO
Write-Host "`nPressione qualquer tecla para abrir o navegador..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Abrir navegador
Start-Process "http://localhost:3000"

Write-Host "`n🎉 Desenvolvimento iniciado com sucesso!" -ForegroundColor Green
