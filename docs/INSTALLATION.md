# Ghost Wallet Hunter - Installation and Deployment Guide

## Overview

This guide covers local setup, configuration, and deployment of Ghost Wallet Hunter. The project uses a monorepo with `backend/` and `frontend/` directories.

### Prerequisites

* **Node.js v18+**
* **Python 3.10+**
* **Git**
* **VSCode** (recommended)
* **Docker** (optional)

### Required Services

* **OpenAI API key** (for AI explanations)
* **Solana RPC endpoint** (mainnet-beta)
* **JuliaOS** (for advanced AI agents)
* **No database required**

## Quick Start

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your-username/ghost-wallet-hunter.git
   cd ghost-wallet-hunter
   ```

2. **Backend Setup**

   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   venv\Scripts\activate    # Windows
   pip install -r backend/requirements.txt
   ```

   * Create and configure a `.env` in `backend/` as needed

3. **Frontend Setup**

   ```bash
   cd frontend
   npm install
   ```

   * Add `.env`:

     ```env
     VITE_BACKEND_URL=http://localhost:8001
     ```

4. **JuliaOS Installation**

   ```bash
   pip install git+https://github.com/juliaoscode/juliaos.git@main#subdirectory=packages/pythonWrapper
   ```

5. **Running Locally**

   * **Backend:**

     ```bash
     uvicorn main:app --reload --port 8001
     ```

   * **Frontend:**

     ```bash
     npm run dev
     ```

   * **Access:** [http://localhost:3000](http://localhost:3000)

## Troubleshooting

* RPC rate limits: Check usage or use a different endpoint
* JuliaOS issues: Update package, check installation
* Port conflicts: Change port in configs
* Check that all `.env` values are set
* Use correct Python/Node versions

## Deployment (Production)

* **Backend:** Deploy to Render, set env variables, build from `/backend`
* **Frontend:** Deploy to Vercel from `/frontend`
* **CI/CD:** Use GitHub Actions for automated tests/builds
* **Monitor:** Logs on Render/Vercel, check endpoints post-deploy

## Maintenance

* Rollback via Render/Vercel dashboard or revert merge on GitHub
* Regularly update dependencies and rotate API keys
