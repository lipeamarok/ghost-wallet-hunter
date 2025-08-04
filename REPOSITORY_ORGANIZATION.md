# 📁 ORGANIZAÇÃO DE ARQUIVOS PARA DEPLOY

## Ghost Wallet Hunter - Estrutura de Repositório

---

## 🎯 **SITUAÇÃO ATUAL**

### **Arquivos na Raiz que PRECISAM ser movidos:**

```text
c:\ghost-wallet-hunter\
├── 📄 render.yaml                    # ✅ MANTER na raiz (config deploy)
├── 📄 prepare_environment.ps1        # ✅ MANTER na raiz (setup local)
├── 📄 start_local_development.ps1    # ✅ MANTER na raiz (dev local)
├── 📄 DATABASE_SETUP_GUIDE.md        # ✅ MANTER na raiz (docs)
├── 📄 README.md                      # ✅ MANTER na raiz (docs)
├── 📄 docker-compose.yml             # ❓ OPCIONAL (dev local)
├──
├── ❌ Manifest.toml                  # MOVER para juliaos-core/
├── ❌ deploy.sh                      # MOVER para scripts/
├── ❌ setup.ps1                      # MOVER para scripts/
├── ❌ setup.sh                       # MOVER para scripts/
├── ❌ start_julia_server.jl          # MOVER para juliaos-core/backend/
├── ❌ test_phase4_integration_updated.py  # MOVER para backend/tests/
```

### **Estrutura Final para Deploy:**

```text
ghost-wallet-hunter/
├── backend/                          # 🐍 Python Backend (Render)
├── frontend/                         # 🌐 React Frontend (Vercel)
├── juliaos-core/                     # 💎 JuliaOS Backend (Render)
├── docs/                             # 📚 Documentação
├── scripts/                          # 🛠️ Scripts de setup
├── render.yaml                       # 🚀 Config deploy
├── README.md                         # 📖 Documentação principal
└── .gitignore                        # 🚫 Ignore files
```

---

## 🔄 **AÇÕES NECESSÁRIAS**

### **1. Mover Arquivos da Raiz**

```powershell
# Criar diretório scripts
mkdir scripts

# Mover scripts de setup
mv deploy.sh scripts/
mv setup.ps1 scripts/
mv setup.sh scripts/

# Mover arquivos Julia
mv Manifest.toml juliaos-core/
mv start_julia_server.jl juliaos-core/backend/

# Mover testes
mv test_phase4_integration_updated.py backend/tests/
```

### **2. Criar Submódulo Git para JuliaOS**

```powershell
# Opção A: Submódulo (RECOMENDADO)
cd juliaos-core
git init
git add .
git commit -m "Initial JuliaOS core"

# Criar repo no GitHub
# git remote add origin https://github.com/lipeamarok/juliaos-core.git
# git push -u origin main

cd ..
git rm -r juliaos-core
git submodule add https://github.com/lipeamarok/juliaos-core.git juliaos-core
```

### **3. Atualizar .gitignore**

```gitignore
# Adicionar ao .gitignore
scripts/*.log
*.tmp
.DS_Store
Thumbs.db
```

---

## 🚀 **ESTRATÉGIA DE DEPLOY NO RENDER**

### **Render.yaml Atualizado:**

```yaml
services:
  - type: web
    name: ghost-backend
    runtime: python
    rootDir: backend                  # ✅ Subdiretório Python

  - type: web
    name: juliaos-core
    runtime: docker
    rootDir: juliaos-core/backend     # ✅ Subdiretório Julia
    dockerfilePath: ./Dockerfile.render
```

### **Por que esta estrutura?**

- ✅ **Render suporta subdirectorios** via `rootDir`
- ✅ **Monorepo organizado** com separação clara
- ✅ **Git submodule** permite versioning independente do JuliaOS
- ✅ **CI/CD simplificado** com um único repositório

---

## 📦 **RESOLUÇÃO DOS IMPORTS JULIAOS**

### **Problema Atual:**

```python
# ❌ Erro nos imports
from juliaos import JuliaOSConnection, Agent
from juliaos.enums import AgentState
from _juliaos_client_api.models import (...)
```

### **Solução:**

```python
# ✅ Import com fallback
try:
    from juliaos import JuliaOSConnection, Agent
    from juliaos.enums import AgentState
    JULIAOS_AVAILABLE = True
except ImportError:
    JULIAOS_AVAILABLE = False
    # Usar cliente HTTP direto para o serviço https://juliaos-core.onrender.com
```

### **Cliente HTTP Alternativo:**

```python
import httpx
import asyncio

class JuliaOSHTTPClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.client = httpx.AsyncClient()

    async def health_check(self):
        try:
            response = await self.client.get(f"{self.base_url}/health")
            return response.status_code == 200
        except:
            return False

    async def list_agents(self):
        response = await self.client.get(f"{self.base_url}/agents")
        return response.json()
```

---

## 🎯 **PLANO DE EXECUÇÃO**

### **Fase 1: Organizar Arquivos (5 min)**

```powershell
# Executar comandos de movimentação
mkdir scripts
mv deploy.sh scripts/
mv setup.ps1 scripts/
mv setup.sh scripts/
mv Manifest.toml juliaos-core/
mv start_julia_server.jl juliaos-core/backend/
mkdir -p backend/tests
mv test_phase4_integration_updated.py backend/tests/
```

### **Fase 2: Corrigir JuliaOS Service (10 min)**

```python
# Implementar cliente HTTP direto
# Testar conectividade com https://juliaos-core.onrender.com
# Validar endpoints
```

### **Fase 3: Git Commit (5 min)**

```powershell
git add .
git commit -m "🚀 Organize repository structure for Render deploy

- Move scripts to scripts/ directory
- Move Julia files to juliaos-core/
- Move tests to backend/tests/
- Update JuliaOS service with HTTP client
- Fix imports for production deployment"
```

---

## ✅ **CHECKLIST FINAL**

- [ ] Arquivos movidos da raiz
- [ ] JuliaOS imports corrigidos
- [ ] Cliente HTTP implementado
- [ ] Render.yaml validado
- [ ] Git commit realizado
- [ ] Deploy testado

**Pronto para execução?** 🚀
