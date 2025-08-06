import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { MagnifyingGlassIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline';
import toast from 'react-hot-toast';
import { investigateWalletDirect, testSystemHealth } from '../../services/directInvestigationAPI';

export default function SimpleInvestigationPage() {
  const [walletAddress, setWalletAddress] = useState('');
  const [isInvestigating, setIsInvestigating] = useState(false);
  const [result, setResult] = useState(null);
  const [systemStatus, setSystemStatus] = useState(null);

  // Validar endereço Solana
  const isValidSolanaAddress = (address) => {
    return /^[1-9A-HJ-NP-Za-km-z]{32,44}$/.test(address);
  };

  // Investigação direta
  const handleInvestigate = async () => {
    if (!walletAddress.trim()) {
      toast.error('Digite um endereço de carteira');
      return;
    }

    if (!isValidSolanaAddress(walletAddress.trim())) {
      toast.error('Endereço Solana inválido');
      return;
    }

    setIsInvestigating(true);
    setResult(null);

    try {
      toast.loading('🔍 Investigando carteira...', { duration: 2000 });

      const investigationResult = await investigateWalletDirect(walletAddress.trim());

      console.log('📊 Investigation result:', investigationResult);

      setResult(investigationResult);

      if (investigationResult.success) {
        toast.success('✅ Investigação concluída!');
      } else {
        toast.error('⚠️ Investigação com problemas');
      }

    } catch (error) {
      console.error('❌ Investigation error:', error);
      toast.error(`Erro: ${error.message}`);

      setResult({
        success: false,
        error: error.message,
        wallet_address: walletAddress.trim()
      });
    } finally {
      setIsInvestigating(false);
    }
  };

  // Testar conectividade
  const handleTestSystem = async () => {
    toast.loading('🔧 Testando sistema...', { duration: 1000 });

    try {
      const status = await testSystemHealth();
      setSystemStatus(status);
      toast.success('✅ Teste de sistema concluído');
    } catch (error) {
      console.error('❌ System test error:', error);
      toast.error(`Erro no teste: ${error.message}`);
    }
  };

  // Renderizar status do sistema
  const renderSystemStatus = () => {
    if (!systemStatus) return null;

    return (
      <div className="bg-gray-800/50 backdrop-blur-sm border border-gray-600 rounded-lg p-4 mb-6">
        <h3 className="text-lg font-semibold text-white mb-3">🔧 Status do Sistema</h3>

        <div className="space-y-2">
          {Object.entries(systemStatus).map(([service, status]) => (
            <div key={service} className="flex items-center gap-3">
              {status.status === 'ok' ? (
                <CheckCircleIcon className="w-5 h-5 text-green-400" />
              ) : (
                <XCircleIcon className="w-5 h-5 text-red-400" />
              )}

              <span className="text-white capitalize">{service.replace('_', ' ')}</span>

              <span className={`text-sm ${
                status.status === 'ok' ? 'text-green-400' : 'text-red-400'
              }`}>
                {status.status === 'ok' ? 'Online' : status.error}
              </span>
            </div>
          ))}
        </div>
      </div>
    );
  };

  // Renderizar resultado da investigação
  const renderResult = () => {
    if (!result) return null;

    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gray-800/50 backdrop-blur-sm border border-gray-600 rounded-lg p-6"
      >
        <h3 className="text-xl font-semibold text-white mb-4">
          📊 Resultado da Investigação
        </h3>

        {result.success ? (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <span className="text-gray-400">Carteira:</span>
                <p className="text-white font-mono text-sm break-all">
                  {result.wallet_address}
                </p>
              </div>

              <div>
                <span className="text-gray-400">Método:</span>
                <p className="text-green-400">{result.method}</p>
              </div>
            </div>

            {result.investigation_data && (
              <div className="bg-gray-900/50 rounded-lg p-4">
                <h4 className="text-white font-semibold mb-2">💰 Dados da Carteira</h4>

                {result.investigation_data.balance_sol !== undefined && (
                  <p className="text-white">
                    <span className="text-gray-400">Saldo:</span> {result.investigation_data.balance_sol} SOL
                  </p>
                )}

                <p className="text-gray-400 text-sm mt-2">
                  Fonte: {result.investigation_data.data_source || result.source}
                </p>

                <p className="text-gray-400 text-xs">
                  {new Date(result.timestamp).toLocaleString()}
                </p>
              </div>
            )}
          </div>
        ) : (
          <div className="text-red-400">
            <p className="font-semibold">❌ Falha na Investigação</p>
            <p className="text-sm mt-2">{result.error}</p>
          </div>
        )}

        {/* Debug info */}
        <details className="mt-4">
          <summary className="text-gray-400 cursor-pointer text-sm">
            🔍 Dados Técnicos
          </summary>
          <pre className="bg-gray-900 rounded p-3 mt-2 text-xs text-gray-300 overflow-auto">
            {JSON.stringify(result, null, 2)}
          </pre>
        </details>
      </motion.div>
    );
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
      <div className="container mx-auto px-4 py-8">

        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">
            🔍 Ghost Wallet Hunter
          </h1>
          <p className="text-gray-300">
            Investigação Direta - Input → Análise → Output
          </p>
        </div>

        <div className="max-w-2xl mx-auto space-y-6">

          {/* Teste de Sistema */}
          <div className="text-center">
            <button
              onClick={handleTestSystem}
              className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm transition-colors"
            >
              🔧 Testar Sistema
            </button>
          </div>

          {/* Status do Sistema */}
          {renderSystemStatus()}

          {/* Input da Carteira */}
          <div className="bg-white/5 backdrop-blur-lg border border-white/10 rounded-xl p-6">
            <div className="flex gap-3">
              <input
                type="text"
                value={walletAddress}
                onChange={(e) => setWalletAddress(e.target.value)}
                placeholder="Digite o endereço da carteira Solana..."
                className="flex-1 bg-gray-800/50 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
                disabled={isInvestigating}
              />

              <button
                onClick={handleInvestigate}
                disabled={isInvestigating || !walletAddress.trim()}
                className="bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white px-6 py-3 rounded-lg font-semibold transition-colors flex items-center gap-2"
              >
                {isInvestigating ? (
                  <>
                    <div className="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full"></div>
                    Investigando...
                  </>
                ) : (
                  <>
                    <MagnifyingGlassIcon className="w-5 h-5" />
                    Investigar
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Resultado */}
          {renderResult()}

          {/* Exemplos */}
          <div className="bg-gray-800/30 rounded-lg p-4">
            <h3 className="text-white font-semibold mb-2">📝 Endereços de Exemplo</h3>
            <div className="grid gap-2">
              {[
                '6sEk1enayZBGFyNvvJMTP7qs5S3uC7KLrQWaEk38hSHH',
                '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
                'DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1'
              ].map((addr) => (
                <button
                  key={addr}
                  onClick={() => setWalletAddress(addr)}
                  className="text-left text-gray-400 hover:text-white text-sm font-mono bg-gray-900/50 hover:bg-gray-800/50 px-3 py-2 rounded transition-colors"
                >
                  {addr}
                </button>
              ))}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
