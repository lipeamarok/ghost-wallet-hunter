# Ghost Wallet Hunter - Quick Setup Guide

## Prerequisites

- **Node.js 18+** - [Download here](https://nodejs.org/)
- **Python 3.10+** - [Download here](https://www.python.org/downloads/)
- **Git** - [Download here](https://git-scm.com/)

## API Keys Required

- **OpenAI API Key** - Get from [OpenAI Platform](https://platform.openai.com/api-keys)
- **Solana RPC** - Free endpoint: `https://api.mainnet-beta.solana.com`

## Quick Setup

### Option 1: Automated Setup (Recommended)

**Windows:**

```powershell
# Run the setup script
.\setup.ps1
```

**Linux/Mac:**

```bash
# Make script executable and run
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

**Backend Setup:**

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your API keys
```

**Frontend Setup:**

```bash
cd frontend
npm install
cp .env.example .env
# Edit .env if needed
```

## Configuration

### Backend (.env)

```env
OPENAI_API_KEY=sk-your-openai-key-here
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
DATABASE_URL=sqlite:///./ghost_wallet_hunter.db
SECRET_KEY=your-super-secret-key
```

### Frontend (.env)

```env
VITE_BACKEND_URL=http://localhost:8000
```

## Running the Application

**Terminal 1 - Backend:**

```bash
cd backend
uvicorn main:app --reload
```

**Terminal 2 - Frontend:**

```bash
cd frontend
npm run dev
```

**Access:** <http://localhost:3000>

## Development Commands

### Backend

```bash
# Run with auto-reload
uvicorn main:app --reload

# Run tests
pytest

# Format code
black .
isort .

# Type checking
mypy .
```

### Frontend

```bash
# Development server
npm run dev

# Build for production
npm run build

# Lint and format
npm run lint
npm run format
```

## Project Structure

```text
ghost-wallet-hunter/
├── backend/          # Python FastAPI backend
├── frontend/         # React frontend
├── docs/            # Documentation
├── setup.sh         # Linux/Mac setup script
├── setup.ps1        # Windows setup script
└── README.md        # Main documentation
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   - Backend: Change port in `uvicorn main:app --reload --port 8001`
   - Frontend: Change port in `vite.config.js`

2. **Python/Node.js not found:**
   - Ensure they're installed and in your PATH

3. **Dependencies fail to install:**
   - Update pip: `python -m pip install --upgrade pip`
   - Clear npm cache: `npm cache clean --force`

4. **Environment variables not loaded:**
   - Ensure `.env` files exist and are properly formatted
   - Restart the development servers

### Need Help?

- Check the [full documentation](docs/) for detailed guides
- Open an issue on GitHub
- Join our Discord community

---

## Ready to hunt some ghost wallets? 👻🔍
