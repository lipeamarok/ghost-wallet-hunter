# Ghost Wallet Hunter

> **AI-powered blockchain analysis with a legendary detective squad. Detect suspicious wallet patterns on Solana using real AI intelligence – fast, secure and production-ready.**

🌐 **Live Demo:** [https://ghostwallethunter.xyz](https://www.ghostwallethunter.xyz)
📚 **API Documentation:** [https://api.ghostwallethunter.xyz/docs](https://api.ghostwallethunter.xyz/docs)
💰 **Cost Dashboard:** [https://api.ghostwallethunter.xyz/ai-costs/dashboard](https://api.ghostwallethunter.xyz/ai-costs/dashboard)

[![Build Status](https://img.shields.io/github/actions/workflow/status/lipeamarok/ghost-wallet-hunter/main.yml?branch=main)](https://github.com/lipeamarok/ghost-wallet-hunter/actions)
[![License](https://img.shields.io/github/license/lipeamarok/ghost-wallet-hunter)](LICENSE)
[![Live Demo](https://img.shields.io/badge/Live%20Demo-ghostwallethunter.xyz-brightgreen)](https://ghostwallethunter.xyz)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/fastapi-0.104+-009688.svg)](https://fastapi.tiangolo.com/)
[![OpenAI Integration](https://img.shields.io/badge/AI-OpenAI%20%2B%20Grok-brightgreen)](https://openai.com/)
[![Docker Ready](https://img.shields.io/badge/deployment-Docker%20Ready-blue)](https://docker.com/)

---

## Overview

**Ghost Wallet Hunter** features a legendary detective squad of 7 specialized AI agents that work together to analyze blockchain transactions and detect suspicious wallet patterns. Each detective brings unique expertise powered by real AI integration (OpenAI + Grok fallback).

### The Legendary Detective Squad

1. **🕵️ Hercule Poirot** - Transaction Analysis & Behavioral Patterns
2. **👵 Miss Jane Marple** - Pattern & Anomaly Detection
3. **🚬 Sam Spade** - Risk Assessment & Threat Classification
4. **🔍 Philip Marlowe** - Bridge & Mixer Tracking
5. **👤 Auguste Dupin** - Compliance & AML Analysis
6. **🌙 The Shadow** - Network Cluster Analysis
7. **🐦‍⬛ Raven** - LLM Explanation & Communication

### What We Solve

- **Hidden wallet connections** across complex transaction networks
- **Risk assessment** with AI-powered threat classification
- **Blacklist verification** against known scam/fraud addresses
- **Clear explanations** of suspicious patterns in plain language
- **Real-time analysis** of Solana blockchain transactions
- **Cost control** with comprehensive AI usage monitoring

---

## Quick Start

### Prerequisites

- **Python 3.11+** with pip
- **Docker & Docker Compose** (recommended for production)
- **Git** for version control
- **API Keys:** OpenAI API key (required), Grok API key (optional)

### Quick Start (Development)

```bash
# Clone the repository
git clone https://github.com/lipeamarok/ghost-wallet-hunter.git
cd ghost-wallet-hunter

# Backend development setup
cd backend
python -m venv venv
# Windows: venv\Scripts\activate
# Linux/Mac: source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env    # Configure your API keys!

# Test the legendary squad
python test_legendary_squad.py
python test_frontend_integration.py

# Start development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Access API docs: http://localhost:8000/docs
```

### Production Deployment (Docker)

```bash
# Set environment variables
export OPENAI_API_KEY=your_openai_key
export GROK_API_KEY=your_grok_key  # Optional
export DB_PASSWORD=secure_password

# Deploy complete system
chmod +x deploy.sh
./deploy.sh

# Or manually with Docker Compose
docker-compose up -d

# Access (Production): https://ghostwallethunter.xyz
# Access (Local Dev): https://localhost (with SSL)
```

### Environment Configuration

**Required Variables (.env or environment):**

```env
# AI Providers (at least OpenAI required)
OPENAI_API_KEY=sk-your-openai-key-here
GROK_API_KEY=your-grok-key-here

# Database
DB_PASSWORD=secure-database-password
DATABASE_URL=postgresql://ghost_user:${DB_PASSWORD}@postgres:5432/ghost_wallet_hunter

# Application
SECRET_KEY=your-super-secure-secret-key
DEBUG=false
ENVIRONMENT=production

# Blockchain
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
```

### API Endpoints (Ready for Frontend)

```bash
# Detective Squad
GET    /api/agents/legendary-squad/status
POST   /api/agents/legendary-squad/investigate
POST   /api/agents/detective/{detective_name}

# AI Cost Management
GET    /api/ai-costs/dashboard
POST   /api/ai-costs/update-limits
GET    /api/ai-costs/providers/status

# Blacklist Security System
GET    /api/v1/blacklist/check/{wallet_address}
POST   /api/v1/blacklist/check-multiple
GET    /api/v1/blacklist/stats
POST   /api/v1/blacklist/force-update

# Health & Testing
GET    /api/health
GET    /api/agents/test/real-ai
```

---

## 📁 Project Structure

```text
ghost-wallet-hunter/
├── backend/                    # Python FastAPI backend
│   ├── agents/                # AI detective agents (7 specialists)
│   ├── api/                   # REST API endpoints
│   ├── models/                # Database models
│   ├── services/              # Business logic & AI integration
│   ├── schemas/               # Pydantic schemas
│   ├── utils/                 # Helper functions
│   ├── config/                # Configuration files
│   ├── tests/                 # Unit and integration tests
│   ├── data/                  # AI cost tracking data
│   ├── main.py                # FastAPI application entry point
│   ├── requirements.txt       # Python dependencies
│   └── .env.example           # Environment template
├── frontend/                   # React + TypeScript frontend
│   ├── src/
│   │   ├── components/        # Reusable UI components
│   │   │   ├── DetectiveSquad/ # Detective management UI
│   │   │   └── CostDashboard/  # AI cost monitoring
│   │   ├── pages/            # Application pages
│   │   ├── hooks/            # Custom React hooks
│   │   ├── services/         # API service layer
│   │   ├── utils/            # Utility functions
│   │   └── App.jsx           # Main React component
│   ├── public/               # Public static files
│   │   ├── ghost-icon.svg    # Application icon
│   │   └── favicon.svg       # Browser favicon
│   ├── dist/                 # Production build output
│   ├── package.json          # Node.js dependencies
│   ├── vite.config.js        # Vite configuration
│   └── .env.production       # Production environment
├── docs/                      # Comprehensive documentation
│   ├── Technical Documentation.md
│   ├── Project Overview.md
│   ├── Installation And Deployment Guide.md
│   ├── Security And Privacy Guide.md
│   ├── Roadmap.md
│   └── FAQ.md
├── updates/                   # Development history & updates
│   ├── DEPLOYMENT_COMPLETE.md
│   ├── IMPLEMENTATION_COMPLETE.md
│   ├── PRODUCTION_RESOLVED.md
│   └── README.md             # Updates folder guide
├── assets/                    # Project assets
├── logs/                      # Application logs
├── .vscode/                   # VS Code configuration
├── README.md                  # Main project documentation
├── SETUP.md                   # Installation guide
├── docker-compose.yml         # Docker deployment
├── deploy.sh                  # Production deployment script
└── .gitignore                # Git ignore rules
```

---

## Key Features

### **AI-Powered Cluster Analysis**

- **JuliaOS Agents** perform autonomous transaction analysis
- **Pattern Recognition** identifies suspicious wallet behaviors
- **Risk Scoring** provides clear threat assessment levels

### **Interactive Visualization**

- **React Flow** based graph visualization
- **Real-time Updates** as new connections are discovered
- **Click-to-Explore** detailed explanations for each connection

### **Intelligent Explanations**

- **OpenAI Integration** generates human-readable analysis
- **Educational Focus** helps users understand blockchain patterns
- **Empathetic Language** avoids technical jargon

### **High Performance**

- **FastAPI Backend** for rapid response times
- **PostgreSQL** caching for repeated queries
- **Solana RPC** optimized for minimal latency

### **Security & Privacy**

- **Public Data Only** - no private key access required
- **Blacklist Integration** - real-time verification against scam databases
- **Multi-source Verification** - Solana Foundation & Chainabuse integration
- **Ethical Guidelines** built into analysis algorithms
- **Transparent Methods** - open source for community review

---

## Technology Stack

### Backend Architecture

- **Language:** Python 3.11+
- **Framework:** FastAPI (REST API + WebSocket)
- **AI Integration:** OpenAI GPT-3.5-turbo + Grok fallback
- **Detective Squad:** 7 specialized AI agents
- **Security:** Multi-source blacklist verification system
- **Cost Tracking:** Real-time AI usage monitoring
- **Blockchain:** Solana.py
- **Database:** PostgreSQL + Redis cache
- **Testing:** Pytest + Custom integration tests
- **Environment:** Docker + Docker Compose

### AI Detective System

- **Smart AI Service:** Multi-provider AI with automatic failover
- **Cost Management:** Real-time tracking, rate limiting, budget controls
- **Detective Agents:** Specialized AI agents for different analysis tasks
- **Real AI Power:** OpenAI integration with Grok fallback
- **Mock Fallback:** Emergency fallback for development/testing

### Frontend Architecture (Ready for Development)

- **Framework:** React.js (API endpoints ready)
- **State Management:** Context API / Redux
- **HTTP Client:** Fetch API / Axios
- **Real-time:** WebSocket integration ready
- **Styling:** TailwindCSS / Styled Components
- **Visualization:** React Flow / D3.js for network graphs

### DevOps & Deployment

- **Containerization:** Docker + Docker Compose
- **Database:** PostgreSQL with automatic initialization
- **Cache:** Redis for performance
- **Reverse Proxy:** Nginx with SSL support
- **Monitoring:** Health checks and error tracking
- **Environment:** Production-ready configuration

---

## Documentation

Comprehensive documentation is available in the `/docs` directory:

- **[📖 Complete Project Overview](docs/Project%20Overview.md)** - Detailed project description and goals
- **[🛠️ Technical Documentation](docs/Technical%20Documentation.md)** - Architecture and implementation details
- **[🚀 Installation & Deployment Guide](docs/Installation%20And%20Deployment%20Guide.md)** - Step-by-step setup instructions
- **[🗺️ Roadmap](docs/Roadmap.md)** - Future development plans and milestones
- **[❓ FAQ](docs/Faq.md)** - Frequently asked questions
- **[🎨 UX/UI Documentation](docs/UX.md)** - Design principles and user experience
- **[🔒 Security & Privacy Guide](docs/Security%20And%20Privacy%20Guide.md)** - Security measures and privacy protection
- **[📈 Scalability Strategy](docs/Scalability%20Strategy.md)** - Performance and scaling approaches
- **[⚖️ Governance](docs/Governance.md)** - Project governance and contribution guidelines
- **[📊 Marketing & Contribution Plan](docs/Marketing%20And%20Contribution%20Plan.md)** - Community engagement strategy

---

## How It Works

### User Journey

1. **Input Wallet Address** - Paste any Solana wallet address or transaction ID
2. **Blacklist Pre-Check** - Instant verification against known scam databases
3. **AI Analysis** - JuliaOS agents analyze blockchain transactions in real-time
4. **Pattern Detection** - System identifies suspicious clustering patterns
5. **Visual Graph** - Interactive React Flow visualization shows wallet connections
6. **AI Explanation** - OpenAI generates clear, educational explanations of findings
7. **Risk Assessment** - Color-coded risk levels (Low/Medium/High) for each cluster

### Analysis Criteria

**Clustering Detection:**

- **Simultaneous Transactions:** 3+ mutual transactions within 48 hours
- **Volume Patterns:** High-volume transfers (configurable thresholds)
- **Timing Analysis:** Identical-value transactions within 1 hour
- **Known Patterns:** Links to mixers, exchanges, or flagged addresses

**Example Analysis:**

```text
Wallet A → 5 transactions with Wallet B in 12 hours, 10 SOL volume
Result: Medium risk cluster detected
```

### Blacklist Security System

**Multi-Source Verification:**

- **Solana Foundation Blacklist** - Official scam address registry
- **Chainabuse Database** - Community-reported fraud addresses
- **Real-time Updates** - Hourly synchronization with latest threat data
- **Redis Caching** - Fast lookup performance for repeated checks

**Protection Features:**

- **Pre-Analysis Check** - Instant verification before full investigation
- **Visual Warnings** - Clear alerts for blacklisted addresses
- **Batch Verification** - Multiple wallet checking capability
- **Force Updates** - Manual blacklist refresh on demand

### API Example

**Endpoint:** `POST /api/analyze`

**Request:**

```json
{
    "wallet_address": "11111111111111111111111111111112"
}
```

**Response:**

```json
{
    "clusters": [
        {
            "wallet": "11111111111111111111111111111113",
            "risk": "high",
            "connections": 5,
            "volume_sol": 25.5,
            "last_activity": "2025-07-27T10:30:00Z"
        }
    ],
    "explanation": "These wallets are directly connected through multiple simultaneous transactions, indicating potential coordinated activity.",
    "risk_score": 0.85,
    "total_connections": 12
}
```

---

## Important Disclaimers

### Ethical Usage

- **Educational Purpose:** All analyses are probabilistic and for educational use
- **Not Financial Advice:** Results should not be used as sole basis for financial decisions
- **Privacy Respect:** Only public blockchain data is analyzed
- **No Accusations:** Tool identifies patterns, not guilt or wrongdoing

### Technical Limitations

- **False Positives:** Some legitimate transactions may appear suspicious
- **Scope:** Currently limited to direct transaction relationships
- **Real-time:** Analysis based on recent blockchain data (not historical deep dive)

---

## Contributing

We welcome contributions from the community! Here's how you can help:

### Development

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Areas of Contribution

- **Bug Reports** - Help us identify and fix issues
- **Feature Requests** - Suggest new capabilities
- **Documentation** - Improve guides and explanations
- **UI/UX** - Enhance user experience
- **Performance** - Optimize algorithms and performance
- **Multi-chain** - Add support for other blockchains

### Code Standards

- **Python:** Follow PEP 8, use type hints, write tests
- **JavaScript:** Use ESLint, Prettier formatting
- **Git:** Write clear commit messages
- **Tests:** Maintain test coverage above 80%

---

## Roadmap

### Current Phase: MVP (Q3 2025)

- ✅ Basic Solana wallet cluster analysis
- ✅ Interactive React visualization
- ✅ AI-powered explanations
- ✅ Multi-source blacklist verification system
- 🔄 Beta testing and community feedback

### Phase 2: Enhanced Analysis (Q4 2025)

- 🔄 Advanced pattern detection (mixers, bridges)
- 🔄 Risk scoring improvements
- 🔄 Performance optimizations
- ✅ Redis caching implementation
- 🔄 Enhanced blacklist sources integration

### Phase 3: Multi-chain Support (Q1 2026)

- 📅 Ethereum integration
- 📅 Binance Smart Chain support
- 📅 Cross-chain analysis
- 📅 Real-time alerts system

### Phase 4: Commercialization (Q2 2026)

- 📅 Freemium model
- 📅 Enterprise API access
- 📅 Detailed report marketplace
- 📅 DAO governance structure

---

## Performance & Metrics

### Current Capabilities

- **Analysis Speed:** < 3 seconds per wallet
- **Accuracy:** ~85% pattern detection rate
- **Supported Networks:** Solana Mainnet-Beta
- **Concurrent Users:** 100+ (with scaling)

### Success Metrics

- **Target Users:** 1,000+ analyses completed in beta
- **Community:** 500+ GitHub stars, 50+ contributors
- **Accuracy Goal:** 90%+ true positive rate
- **Performance:** < 2 seconds average response time

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Open Source Commitment

Ghost Wallet Hunter is committed to transparency and open-source development:

- **Full Source Code** available for review
- **Community Driven** development and governance
- **Educational Focus** for blockchain security awareness
- **Ethical AI** principles in all implementations

---

## Support & Community

### Get Help

- **Documentation:** Comprehensive guides in `/docs`
- **Issues:** [GitHub Issues](https://github.com/lipeamarok/ghost-wallet-hunter/issues)
- **Discussions:** [GitHub Discussions](https://github.com/lipeamarok/ghost-wallet-hunter/discussions)
- **Email:** 'soon'

### Community Channels

- **Twitter:** 'soon'
- **Discord:** 'soon'
- **YouTube:** 'soon'

---

**Ghost Wallet Hunter** - *Radical transparency and security for everyone in the blockchain universe.*

---

*Built with ❤️ by the community for the community. Empowering safer blockchain interactions through AI-powered analysis and education.*
