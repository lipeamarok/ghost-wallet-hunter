# Ghost Wallet Hunter - Installation and Deployment Guide

## Overview

This guide covers local setup, configuration, and deployment of the Ghost Wallet Hunter MVP. Assumes a Linux/Mac/Windows environment with Git installed. The project uses a monorepo structure with separate `backend/` and `frontend/` directories for streamlined CI/CD.

## Prerequisites and Requirements

### System Requirements

* **System:** Node.js v18+, Python 3.10+, Git
* **Tools:** VSCode (recommended), Docker (optional for containerization)

### API Keys and Services

* **APIs:** OpenAI API key (free for testing), Solana RPC (free mainnet-beta endpoint)
* **AI Framework:** JuliaOS for enhanced AI agent capabilities
* **Database:** Not required - stateless architecture

## Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/ghost-wallet-hunter.git
cd ghost-wallet-hunter
```

### 2. Backend Setup (Python)

Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate    # Windows
```

Install dependencies:

```bash
pip install -r backend/requirements.txt
```

Create and configure the `.env` file in the `backend/` directory with the required environment variables.

### 3. Frontend Setup (React)

Navigate to frontend:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file with:

```env
VITE_BACKEND_URL=http://localhost:8001
```

### 4. JuliaOS Setup

Install JuliaOS wrapper directly from GitHub:

```bash
pip install git+https://github.com/juliaoscode/juliaos.git@main#subdirectory=packages/pythonWrapper
```

The backend will automatically initialize JuliaOS agents when needed.

### 5. Running the Application Locally

**Backend:**

```bash
uvicorn main:app --reload --port 8001
```

**Frontend:** (Coming soon - React + Vite implementation)

```bash
npm run dev
```

Access the application at:

* **Development:** [http://localhost:3000](http://localhost:3000)
* **Production:** [https://ghostwallethunter.xyz](https://ghostwallethunter.xyz)

API Documentation:

* **Development:** [http://localhost:8001/docs](http://localhost:8001/docs)
* **Production:** [https://api.ghostwallethunter.xyz/docs](https://api.ghostwallethunter.xyz/docs)

---

## Troubleshooting

### Common Issues

* **Solana RPC rate limits:** Check your RPC endpoint usage limits
* **JuliaOS SDK issues:** Update to the latest version if problems arise
* **Installation errors:** Clear pip/npm cache and retry
* **Port conflicts:** Change port numbers in configuration files

### Quick Diagnostic Checklist

* Ensure all required `.env` variables are set correctly
* Confirm Node.js and Python versions meet minimum requirements
* If "connection refused" to Solana RPC, try a testnet endpoint
* For deployment issues, check logs and GitHub repository permissions

---

## Production Deployment

### 1. Backend Deployment on Render

* Create a Web Service pointing to the `/backend` subdirectory
* Configure build and start commands according to your requirements
* Set all required environment variables in the Render dashboard

### 2. Frontend Deployment on Vercel

* Import the repository pointing to the `/frontend` subdirectory
* Configure build settings and environment variables
* Enable automatic deployments from your main branch

### 3. Continuous Integration and Deployment

* Set up GitHub Actions to automate tests and build verification
* Configure automated deployment triggers for both services

### 4. Post-Deployment Verification

* Access the deployed Vercel URL and test application functionality
* Monitor logs on both Render and Vercel for any issues
* Verify all API endpoints are working correctly

---

## Maintenance and Operations

### Emergency Rollback Procedures

* In Render/Vercel, go to the deployment history and click "Redeploy" on the last stable version
* On GitHub, use the "Revert" option on problematic merges and trigger a redeploy
* Always maintain a `main-stable` branch as a backup for emergencies

### Regular Maintenance Tasks

* Regularly update dependencies to latest stable versions
* Back up your PostgreSQL database according to your backup strategy
* Monitor usage metrics and upgrade to paid plans as usage grows
* Review and rotate API keys periodically for security
