# Ghost Wallet Hunter - API Endpoints Documentation

## 📋 Visão Geral da Arquitetura

O Ghost Wallet Hunter utiliza uma arquitetura multi-camadas com três serviços principais:

### **🔧 Serviços Principais**

1. **Backend Python (FastAPI)** - `localhost:8001`
   - API principal para frontend
   - Orquestração de investigações
   - Integração A2A

2. **JuliaOS Core** - `localhost:8052`
   - Engine de alta performance
   - Smart RPC Pool para Solana
   - Agentes especializados

3. **A2A Server** - `localhost:9100`
   - Protocolo Agent-to-Agent
   - Coordenação de swarm
   - Bridge Julia ↔ Python

---

## 🐍 Backend Python (FastAPI) - Port 8001

### **🚀 MAIN FRONTEND API (`/api/v1/`)**

#### **WebSocket**

```http
WS /api/v1/ws/investigations
- Real-time investigation updates
```

#### **Wallet Investigation**

```http
POST /api/v1/wallet/investigate
Body: { wallet_address: string, investigation_type?: string }
- Main wallet investigation endpoint
- Triggers A2A squad investigation

POST /api/v1/wallet/investigate/test
Body: { wallet_address: string }
- Test investigation endpoint

POST /api/v1/wallet/investigate/demo
Body: { wallet_address: string }
- Demo investigation with instant results
```

#### **Squad Management**

```http
GET /api/v1/squad/status
- Real-time A2A detective squad status
- Returns: { status, detectives_active, julia_connection }

GET /api/v1/detectives
- List all available legendary detectives
- A2A specialties and capabilities

GET /api/v1/detectives/available
- Alias for /detectives endpoint
```

#### **AI Cost Management**

```http
GET /api/v1/ai-costs/dashboard
- AI cost dashboard data
- Usage statistics, limits, alerts

POST /api/v1/ai-costs/update-limits
Body: { daily_limit: number, per_user_limit: number }
- Update AI cost limits for budget control
```

#### **System Health & Testing**

```http
GET /api/v1/health
- Frontend health check endpoint
- A2A integration status

GET /api/v1/test/integration
- Complete system integration test
- A2A + Julia + AI services

GET /api/v1/test/juliaos
- Test A2A backend connection
- Julia bridge connectivity
```

---

### **🤖 AGENTS & DETECTIVES (`/api/agents/`)**

#### **A2A Integration**

```json
POST /api/agents/legendary-squad/investigate
Body: { wallet_address: string, investigation_type: string }
- Full squad investigation via A2A

POST /api/agents/detective/{detective_id}/analyze
Body: { wallet_address: string, focus_area?: string }
- Individual detective analysis

GET /api/agents/available
- Available A2A detectives

GET /api/agents/health
- A2A detective squad health check
```

---

### **📊 ANALYSIS ROUTES (`/api/analysis/`)**

```json
POST /api/analysis/analyze
Body: { wallet_address: string, depth?: string }
- Main wallet analysis endpoint
- Returns: clustering data, risk assessment

GET /api/analysis/analyze/quick/{wallet_address}
- Quick wallet analysis
- Faster response, basic data

GET /api/analysis/patterns
- Get analysis patterns and trends
```

---

### **🛡️ BLACKLIST VERIFICATION (`/api/v1/blacklist/`)**

```json
GET /api/v1/blacklist/check/{wallet_address}
- Check single wallet against blacklist

POST /api/v1/blacklist/check-multiple
Body: { wallet_addresses: string[] }
- Bulk blacklist verification

GET /api/v1/blacklist/stats
- Blacklist statistics and status

POST /api/v1/blacklist/update
- Force blacklist update

GET /api/v1/blacklist/search/{query}
- Search blacklist entries

GET /api/v1/blacklist/random-example
- Get random blacklist example
```

---

### **💰 AI COSTS MANAGEMENT (`/api/ai-costs/`)**

```json
GET /api/ai-costs/dashboard
- Complete cost dashboard data

POST /api/ai-costs/update-limits
Body: { daily_limit: number, per_user_limit: number }
- Update spending limits

GET /api/ai-costs/usage/{user_id}
- User-specific usage statistics

POST /api/ai-costs/alerts/setup
Body: { threshold: number, email?: string }
- Setup cost alerts

GET /api/ai-costs/providers/status
- AI providers status (OpenAI, Grok, etc.)

GET /api/ai-costs/health
- AI costs service health
```

---

### **📈 PERFORMANCE MONITORING (`/api/performance/`)**

```json
GET /api/performance/status
- Overall system performance

GET /api/performance/juliaos/status
- JuliaOS integration status

GET /api/performance/cache/stats
- Cache performance statistics

POST /api/performance/cache/cleanup
- Manual cache cleanup

GET /api/performance/analysis/timing
- Analysis timing reports

GET /api/performance/health
- Performance monitoring health
```

---

### **🏥 HEALTH & SYSTEM (`/api/health/`)**

```json
GET /api/health
- Basic health check

GET /api/health/detailed
- Detailed health with AI services

GET /api/health/version
- Application version info
```

---

## 🔮 JuliaOS Core - Port 8052

### **Core Julia Server Endpoints**

#### **Health & Status**

```json
GET /health
GET /api/health
GET /api/v1/health
- Julia server health check
- Service status and metrics
```

#### **Agent Management**

```json
GET /api/v1/agents
- List all Julia agents
- Detective squad information

GET /api/v1/agents/{agent_id}
- Get specific agent details

POST /api/v1/agents
- Create new agent

PUT /api/v1/agents/{agent_id}
- Update agent configuration

DELETE /api/v1/agents/{agent_id}
- Delete agent
```

#### **Agent Operations**

```json
POST /api/v1/agents/{agent_id}/start
- Start agent execution

POST /api/v1/agents/{agent_id}/stop
- Stop agent execution

POST /api/v1/agents/{agent_id}/pause
- Pause running agent

POST /api/v1/agents/{agent_id}/resume
- Resume paused agent
```

#### **Task Management**

```json
POST /api/v1/agents/{agent_id}/tasks
- Submit task to agent

GET /api/v1/agents/{agent_id}/tasks
- List agent tasks

GET /api/v1/agents/{agent_id}/tasks/{task_id}
- Get task status

GET /api/v1/agents/{agent_id}/tasks/{task_id}/result
- Get task result

POST /api/v1/agents/{agent_id}/tasks/{task_id}/cancel
- Cancel task
```

#### **Agent Memory**

```json
GET /api/v1/agents/{agent_id}/memory/{key}
- Get agent memory value

POST /api/v1/agents/{agent_id}/memory/{key}
- Set agent memory value

DELETE /api/v1/agents/{agent_id}/memory
- Clear agent memory
```

#### **Investigation Endpoints**

```json
POST /api/v1/investigate/squad
Body: { wallet_address: string }
- Squad-based investigation

POST /api/v1/agents/{agent_type}/investigate
Body: { wallet_address: string }
- Individual agent investigation
```

#### **Test Endpoints**

```json
GET /api/v1/test/hello
- Basic connectivity test

POST /api/v1/test/post
Body: JSON
- Test POST functionality
```

---

## 🌉 A2A Server - Port 9100

### **A2A Protocol Endpoints**

#### **Core Status**

```json
GET /health
- A2A server health check
- Julia bridge status

GET /status
- Server status overview

GET /julia/health
- Julia bridge connectivity

GET /julia/connection
- Test Julia connection
```

#### **Agent Management_2**

```json
GET /agents
- List all A2A agents
- Real agents from Julia bridge

GET /agents/count
- Count of available agents

GET /{agent_id}/card
- Get agent card details
- Capabilities and specialties

GET /{agent_id}/status
- Individual agent status
```

#### **Investigation Operations**

```json
POST /{agent_id}/investigate
Body: { wallet_address: string }
- Agent-specific investigation

POST /{agent_id}/message
Body: { message: string, context?: object }
- Send message to agent

POST /{agent_id}/analyze
Body: { wallet_address: string, analysis_type?: string }
- Agent analysis request
```

#### **Swarm Coordination**

```json
POST /swarm/investigate
Body: { wallet_address: string, coordination_type?: string }
- 🔥 COORDINATED SWARM INVESTIGATION
- Multiple agents working together

GET /swarm/status
- Swarm coordination status

GET /swarm/agents
- Agents participating in swarm
```

#### **Development & Testing**

```json
GET /test/connectivity
- Complete connectivity test

GET /debug/agents
- Debug agents state
- Detailed agent information
```

---

## 🔗 Frontend Integration Examples

### **Basic Investigation**

```javascript
// Main investigation call
const investigateWallet = async (walletAddress) => {
  const response = await fetch('/api/v1/wallet/investigate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      wallet_address: walletAddress,
      investigation_type: 'comprehensive'
    })
  });
  return response.json();
};
```

### **Real-time Updates via WebSocket**

```javascript
const ws = new WebSocket('ws://localhost:8001/api/v1/ws/investigations');
ws.onmessage = (event) => {
  const update = JSON.parse(event.data);
  // Handle real-time investigation updates
};
```

### **Squad Status Check**

```javascript
const getSquadStatus = async () => {
  const response = await fetch('/api/v1/squad/status');
  return response.json();
};
```

### **AI Cost Dashboard**

```javascript
const getCostDashboard = async () => {
  const response = await fetch('/api/v1/ai-costs/dashboard');
  return response.json();
};
```

---

## 🌐 URL Patterns by Environment

### **Development**

```shell
Backend:  http://localhost:8001
JuliaOS:  http://localhost:8052
A2A:      http://localhost:9100
Frontend: http://localhost:5173
```

### **Production (Render)**

```shell
Backend:  https://ghost-backend.onrender.com
JuliaOS:  https://ghost-julia.onrender.com
A2A:      Internal network (via julia service)
Frontend: https://ghost-wallet-hunter.vercel.app
```

---

## 🚨 Important Notes

### **Authentication**

- Most endpoints are public in development
- Production uses API keys for sensitive operations
- CORS configured for frontend integration

### **Rate Limiting**

- Smart RPC pool prevents Solana rate limits
- Internal rate limiting on investigation endpoints
- AI cost limits prevent overspending

### **Error Handling**

- Consistent error format across all services
- HTTP status codes follow REST conventions
- Detailed error messages in development

### **Real-time Features**

- WebSocket for investigation updates
- A2A protocol for agent coordination
- Live cost monitoring

---

## 📱 Frontend API Priority List

### **Essential for Frontend (Priority 1)**

1. `POST /api/v1/wallet/investigate` - Main investigation
2. `WS /api/v1/ws/investigations` - Real-time updates
3. `GET /api/v1/squad/status` - Squad status
4. `GET /api/v1/health` - System health
5. `GET /api/v1/ai-costs/dashboard` - Cost monitoring

### **Enhanced Features (Priority 2)**

1. `GET /api/v1/detectives` - Detective information
2. `POST /api/v1/wallet/investigate/demo` - Demo mode
3. `GET /api/v1/blacklist/check/{wallet}` - Security check
4. `GET /api/v1/test/integration` - System status

### **Advanced Features (Priority 3)**

1. `POST /api/agents/legendary-squad/investigate` - Direct A2A
2. `GET /api/performance/status` - Performance metrics
3. `POST /api/ai-costs/update-limits` - Admin controls

---

## 🔮 Next Steps for Frontend Integration

1. **Implement main investigation flow** using priority endpoints
2. **Add WebSocket integration** for real-time updates
3. **Create cost monitoring dashboard** with AI spending limits
4. **Add detective squad status** visualization
5. **Implement demo mode** for instant results
6. **Add system health indicators** for monitoring

**Ready for frontend integration! 🚀*
