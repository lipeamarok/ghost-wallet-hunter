// DIRECT INVESTIGATION API - SIMPLES E FUNCIONAL
// Input → Análise Real → Output

import axios from 'axios';

const JULIA_URL = 'http://localhost:10000';
const BACKEND_URL = 'http://localhost:8001';

// API direta para investigação simples
export class DirectInvestigationAPI {
  constructor() {
    this.juliaAPI = axios.create({
      baseURL: JULIA_URL,
      timeout: 30000,
      headers: { 'Content-Type': 'application/json' }
    });

    this.backendAPI = axios.create({
      baseURL: BACKEND_URL,
      timeout: 30000,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // MÉTODO PRINCIPAL: Investigação Direta
  async investigateWallet(walletAddress) {
    console.log('🚀 Starting DIRECT investigation for:', walletAddress);

    try {
      // 1. Verificar se Julia está online
      const juliaHealth = await this.checkJuliaHealth();
      if (!juliaHealth.ok) {
        throw new Error('Julia server não está respondendo');
      }

      // 2. Investigação direta via Julia
      console.log('📡 Connecting directly to Julia for investigation...');

      const investigationResponse = await this.juliaAPI.post('/api/v1/investigate', {
        wallet_address: walletAddress,
        investigation_type: 'direct',
        source: 'frontend_direct'
      });

      console.log('✅ Julia investigation completed:', investigationResponse.data);

      // 3. Processar resultado
      const result = {
        success: true,
        wallet_address: walletAddress,
        investigation_data: investigationResponse.data,
        source: 'julia_direct',
        timestamp: new Date().toISOString(),
        method: 'direct_api_call'
      };

      return result;

    } catch (error) {
      console.error('❌ Direct investigation failed:', error);

      // Fallback: Análise básica com Solana RPC
      return await this.fallbackBasicAnalysis(walletAddress);
    }
  }

  // Verificar saúde do Julia
  async checkJuliaHealth() {
    try {
      const response = await this.juliaAPI.get('/health');
      console.log('✅ Julia health check:', response.data);
      return { ok: true, data: response.data };
    } catch (error) {
      console.error('❌ Julia health check failed:', error);
      return { ok: false, error: error.message };
    }
  }

  // Listar agentes disponíveis
  async getAvailableAgents() {
    try {
      const response = await this.juliaAPI.get('/api/v1/agents');
      console.log('🕵️ Available agents:', response.data);
      return response.data;
    } catch (error) {
      console.error('❌ Failed to get agents:', error);
      return { agents: [], error: error.message };
    }
  }

  // Análise básica de fallback
  async fallbackBasicAnalysis(walletAddress) {
    console.log('🔄 Using fallback basic analysis...');

    try {
      // Chamada básica para Solana RPC
      const response = await fetch('https://api.mainnet-beta.solana.com', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'getBalance',
          params: [walletAddress]
        })
      });

      const data = await response.json();
      const balance = data.result?.value || 0;

      return {
        success: true,
        wallet_address: walletAddress,
        investigation_data: {
          balance_sol: balance / 1000000000,
          balance_lamports: balance,
          data_source: 'solana_rpc_direct',
          analysis_type: 'basic_fallback',
          timestamp: new Date().toISOString(),
          note: 'Análise básica - Julia server não disponível'
        },
        source: 'fallback_rpc',
        timestamp: new Date().toISOString(),
        method: 'solana_rpc_direct'
      };

    } catch (error) {
      console.error('❌ Fallback analysis failed:', error);

      return {
        success: false,
        wallet_address: walletAddress,
        error: `Falha na investigação: ${error.message}`,
        source: 'error',
        timestamp: new Date().toISOString(),
        method: 'failed'
      };
    }
  }

  // Teste de conectividade completo
  async testConnectivity() {
    const results = {
      julia: { status: 'testing' },
      backend: { status: 'testing' },
      solana_rpc: { status: 'testing' }
    };

    // Teste Julia
    try {
      await this.juliaAPI.get('/api/v1/test/hello');
      results.julia = { status: 'ok', url: JULIA_URL };
    } catch (error) {
      results.julia = { status: 'error', error: error.message };
    }

    // Teste Backend
    try {
      await this.backendAPI.get('/api/v1/health');
      results.backend = { status: 'ok', url: BACKEND_URL };
    } catch (error) {
      results.backend = { status: 'error', error: error.message };
    }

    // Teste Solana RPC
    try {
      const response = await fetch('https://api.mainnet-beta.solana.com', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'getHealth'
        })
      });

      if (response.ok) {
        results.solana_rpc = { status: 'ok', url: 'https://api.mainnet-beta.solana.com' };
      } else {
        results.solana_rpc = { status: 'error', error: `HTTP ${response.status}` };
      }
    } catch (error) {
      results.solana_rpc = { status: 'error', error: error.message };
    }

    return results;
  }
}

// Instância singleton
const directAPI = new DirectInvestigationAPI();

export default directAPI;

// Função simples para uso direto
export const investigateWalletDirect = async (walletAddress) => {
  return await directAPI.investigateWallet(walletAddress);
};

export const testSystemHealth = async () => {
  return await directAPI.testConnectivity();
};
