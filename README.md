# 🕵️ Ghost Wallet Hunter

> **Solana Wallet Analysis with Julia Backend**
> *AI-Powered Detective Squad for Blockchain Investigation*

🔍 **Simple Architecture:** React Frontend + Julia Backend
⚡ **High-Performance Computing:** Julia Engine for Blockchain Analysis
🕵️ **Detective Squad:** 7 Specialized Julia Agents
🟣 **Solana Focus:** Dedicated Solana Blockchain Analysis

[![Julia Backend](https://img.shields.io/badge/Backend-Julia-purple)](https://julialang.org/)
[![React Frontend](https://img.shields.io/badge/Frontend-React%20+%20Vite-blue)](https://vitejs.dev/)
[![Solana](https://img.shields.io/badge/Blockchain-Solana%20Only-green)](https://solana.com/)
[![Development](https://img.shields.io/badge/Status-Development-yellow)](https://github.com/lipeamarok/ghost-wallet-hunter)

---

## Overview

**Ghost Wallet Hunter** is a Solana blockchain analysis tool featuring a React frontend and Julia backend. The system uses 7 specialized detective agents to analyze wallet addresses and transactions on the Solana blockchain.

### Architecture

#### **🚀 Julia Backend Server**

High-performance Julia server (`juliaos/core/`) running on port 10000:

- **Solana Integration**: Direct connection to Solana RPC endpoints
- **Detective Agents**: 7 specialized investigation agents
- **HTTP API**: RESTful endpoints for frontend communication
- **Real-time Analysis**: Live Solana blockchain data processing

#### **⚛️ React Frontend**

Modern React application (`frontend/`) running on port 3000:

- **Vite Build System**: Fast development and building
- **Investigation Interface**: User-friendly wallet analysis interface
- **Results Display**: Detailed detective findings and risk assessment
- **Responsive Design**: Mobile and desktop support

#### **🕵️ The Detective Squad (7 Specialized Agents)**

Each detective is implemented in Julia with unique expertise:

1. **🎩 Hercule Poirot** - Transaction Analysis
   - Methodical transaction flow analysis
   - Fund flow tracing and token identification

2. **👵 Miss Jane Marple** - Pattern Detection
   - Statistical anomaly detection
   - Behavioral analysis and pattern recognition

3. **🚬 Sam Spade** - Risk Assessment
   - Threat classification and security scoring
   - Risk tolerance evaluation

4. **🌃 Philip Marlowe** - Deep Investigation
   - Complex transaction chain analysis
   - Hidden connection discovery

5. **👤 Auguste Dupin** - Analytical Deduction
   - Pure analytical reasoning and logical deduction
   - Mathematical precision in pattern analysis

6. **🌙 The Shadow** - Network Analysis
   - Cluster analysis and connection mapping
   - Network topology investigation

7. **🐦‍⬛ Detective Raven** - Report Synthesis
   - Final report compilation and analysis summary
   - Risk score calculation and recommendations

### What Makes This System Unique

#### **Julia-Powered Analysis**

- **High Performance**: Julia's speed for numerical computing and blockchain analysis
- **Detective Squad**: 7 specialized agents with unique investigation approaches
- **Real Data**: Direct Solana blockchain integration with live transaction data
- **Modular Design**: Each detective can be used independently or in combination

#### **Simple but Effective**

- **Two-Layer Architecture**: Clean separation between Julia backend and React frontend
- **Focused Scope**: Solana-only for deep, specialized analysis
- **Real-time Results**: Fast analysis with immediate feedback
- **Educational Purpose**: Clear explanations of findings and risk factors

---

## Quick Start

### 📋 Prerequisites

- **Julia 1.11+** - Backend computation engine ([Install Julia](https://julialang.org/downloads/))
- **Node.js 18+** - Frontend development ([Install Node.js](https://nodejs.org/))
- **Git** - Version control

### Development Setup

#### **1. Clone Repository**

```bash
git clone https://github.com/lipeamarok/ghost-wallet-hunter.git
cd ghost-wallet-hunter
```

#### **2. Julia Backend Setup**

```bash
# Navigate to Julia backend
cd juliaos/core

# Install Julia dependencies
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Start Julia server (Port 10000)
julia start_julia_server.jl
```

#### **3. React Frontend Setup**

```bash
# Navigate to frontend
cd frontend

# Install Node.js dependencies
npm install

# Start development server (Port 3000)
npm run dev
```

### Verify Setup

```bash
# Test Julia Backend
curl http://localhost:10000/health

# Test Frontend
# Open browser to http://localhost:3000
```

### Usage

1. **Open Frontend**: Navigate to `http://localhost:3000`
2. **Enter Wallet Address**: Input a Solana wallet address
3. **Start Investigation**: Click "Investigate" to run detective analysis
4. **View Results**: Review findings from all 7 detectives
5. **Risk Assessment**: Check overall risk score and recommendations

---

## 📁 Project Structure

```text
ghost-wallet-hunter/
├── frontend/                     # React Frontend Application
│   ├── src/
│   │   ├── components/           # React components
│   │   │   ├── Forms/           # Investigation forms
│   │   │   ├── Results/         # Results display components
│   │   │   └── Shared/          # Shared UI components
│   │   ├── pages/               # Page components
│   │   │   ├── InvestigationPage.jsx  # Main investigation interface
│   │   │   └── ResultsPage.jsx   # Results display page
│   │   ├── services/            # API services
│   │   │   ├── investigation.service.js  # Investigation API
│   │   │   └── julia.service.js  # Julia backend communication
│   │   ├── types/               # Type definitions
│   │   │   └── investigation.types.js  # Investigation types
│   │   └── App.jsx              # Main React application
│   ├── package.json             # Node.js dependencies
│   ├── vite.config.js           # Vite configuration
│   └── index.html               # HTML entry point
├── juliaos/                     # Julia Backend System
│   └── core/                    # Julia computation engine
│       ├── start_julia_server.jl  # Main server (Port 10000)
│       ├── revolutionary_julia_server.jl  # Server implementation
│       ├── Project.toml         # Julia dependencies
│       └── src/                 # Julia source code
│           └── agents/          # Detective agent implementations
├── backup/                      # Development backups and experiments
├── monitoring/                  # System monitoring tools
├── scripts/                     # Utility scripts
└── updates/                     # Documentation and updates
```

### **Key Files**

#### **Frontend (React + Vite)**

- `frontend/src/pages/InvestigationPage.jsx` - Main investigation interface
- `frontend/src/pages/ResultsPage.jsx` - Detective results display
- `frontend/src/services/julia.service.js` - Backend communication
- `frontend/src/types/investigation.types.js` - 7 detective definitions

#### **Backend (Julia)**

- `juliaos/core/start_julia_server.jl` - Main Julia server
- `juliaos/core/revolutionary_julia_server.jl` - HTTP server implementation
- `juliaos/core/Project.toml` - Julia package dependencies

---

## Key Features

### **Blockchain Analysis**

- **Solana Focused**: Deep analysis of Solana transactions and addresses
- **7 Detective Agents**: Each with specialized investigation techniques
- **Real Data**: Direct connection to Solana blockchain (no mock data)
- **Risk Assessment**: Comprehensive risk scoring and threat detection

### **User-Friendly Interface**

- **React Frontend**: Modern, responsive web interface
- **Interactive Results**: Detailed breakdown of detective findings
- **Real-time Analysis**: Fast investigation with immediate results
- **Educational Explanations**: Clear descriptions of findings and risks

### **High Performance**

- **Julia Backend**: Optimized for numerical computing and blockchain analysis
- **Fast Processing**: Quick wallet analysis and pattern detection
- **Efficient API**: Simple HTTP communication between frontend and backend

### **Security & Privacy**

- **Public Data Only**: No private key access required
- **Transparent Methods**: Open source for community review
- **Educational Purpose**: Focus on learning and security awareness
- **Ethical Guidelines**: Responsible analysis and reporting

---

## Technology Stack

### **Frontend (React + Vite)**

- **Language:** JavaScript/JSX
- **Framework:** React 18+ for modern user interface
- **Build Tool:** Vite for fast development and building
- **Routing:** React Router for navigation
- **Styling:** Tailwind CSS for responsive design
- **HTTP Client:** Fetch API for backend communication
- **Development Server:** Port 3000

### **Backend (Julia)**

- **Language:** Julia 1.11+ for high-performance computing
- **HTTP Server:** Julia HTTP.jl with custom middleware
- **API:** RESTful endpoints for frontend communication
- **Detective System:** 7 specialized agent implementations
- **Blockchain:** Direct Solana RPC integration
- **Port:** 10000

### **Blockchain Integration**

- **Network:** Solana Mainnet-Beta
- **Data Source:** Real-time Solana RPC endpoints
- **Analysis:** Transaction patterns, wallet behavior, risk assessment
- **Coverage:** Solana ecosystem only (focused approach)

---

## How It Works

### **Investigation Process**

#### **1. Frontend Request**

User enters a Solana wallet address in the React interface and clicks "Investigate".

#### **2. Backend Analysis**

React frontend sends HTTP request to Julia backend (port 10000) with the wallet address.

#### **3. Detective Squad Execution**

Julia backend runs 7 specialized detective agents:

```julia
# Each detective analyzes the wallet with their specialty
detectives = ["poirot", "marple", "spade", "marlowe", "dupin", "shadow", "raven"]

# Run investigation
for detective in detectives
    result = run_detective_analysis(detective, wallet_address)
    investigation_results[detective] = result
end
```

#### **4. Result Compilation**

All detective findings are compiled into a comprehensive report with:
- Individual detective assessments
- Overall risk score
- Detailed explanations
- Recommendations

#### **5. Frontend Display**

Results are displayed in the React interface showing each detective's findings and overall assessment.

### **Real-Time Data**

- **Direct Solana Connection**: No mocked data, real blockchain analysis
- **Live Transactions**: Current transaction patterns and wallet behavior
- **Up-to-date Analysis**: Fresh data for each investigation

---

## Current Status

### **✅ Working Features**

- **Julia Backend**: Functional server on port 10000
- **7 Detective Agents**: All detectives implemented and operational
- **React Frontend**: Modern interface for wallet investigation
- **Solana Integration**: Real blockchain data analysis
- **Basic Investigation Flow**: End-to-end wallet analysis

### **🔧 Known Issues**

- **Frontend Data Display**: Some detective results may not display correctly
- **Error Handling**: Limited error handling in some scenarios
- **UI Polish**: Interface needs refinement and improved user experience

### **🎯 Development Focus**

- **Bug Fixes**: Resolve frontend display issues
- **Error Handling**: Improve error messages and recovery
- **User Experience**: Polish interface and add better feedback
- **Performance**: Optimize analysis speed and reliability

---

## Important Disclaimers

### Ethical Usage

- **Educational Purpose**: All analyses are probabilistic and for educational use
- **Not Financial Advice**: Results should not be used as sole basis for financial decisions
- **Privacy Respect**: Only public blockchain data is analyzed
- **No Accusations**: Tool identifies patterns, not guilt or wrongdoing

### Technical Limitations

- **False Positives**: Some legitimate transactions may appear suspicious
- **Scope**: Currently limited to Solana blockchain only
- **Development Status**: Project is in active development with known issues

---

## Contributing

We welcome contributions to improve the Ghost Wallet Hunter project!

### **How to Help**

- **Bug Reports**: Report issues in GitHub Issues
- **Feature Requests**: Suggest improvements
- **Code Contributions**: Submit pull requests for fixes and features
- **Documentation**: Help improve documentation and guides

### **Development Areas**

- **Frontend**: React components and user interface improvements
- **Backend**: Julia detective agents and analysis algorithms
- **Testing**: Test coverage and automated testing
- **Documentation**: README updates and code documentation

---

## License & Community

### **Open Source**

Ghost Wallet Hunter is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### **Community Values**

- **Transparency**: Complete source code available for review
- **Education**: Blockchain security awareness and learning
- **Ethics**: Responsible development and usage guidelines
- **Collaboration**: Community-driven development

### **Support**

- **GitHub Issues**: [Report bugs and request features](https://github.com/lipeamarok/ghost-wallet-hunter/issues)
- **GitHub Discussions**: [Community discussions](https://github.com/lipeamarok/ghost-wallet-hunter/discussions)

---

**Ghost Wallet Hunter** - *Solana blockchain analysis with Julia-powered detective agents.*

---

*Built with Julia computing power and React frontend for transparent, educational blockchain security analysis.*
