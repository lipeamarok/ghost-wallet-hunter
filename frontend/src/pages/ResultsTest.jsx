// src/pages/ResultsTest.jsx

import React from "react";
import ThreeBackground from "../components/Background/ThreeBackground"; // seu background animado/estático
import ResultHeader from "../components/Results/ResultHeader";
import AIExplanation from "../components/Results/AIExplanation";
import SuspiciousConnections from "../components/Results/SuspiciousConnections";
import NetworkGraph from "../components/Results/NetworkGraph";
import TimelineEvents from "../components/Results/TimelineEvents";
import SuspiciousTxList from "../components/Results/SuspiciousTxList";
import ExportButton from "../components/Results/ExportButton";

// --- Dados fake para simular resposta da API ---
const resultData = {
  risk_score: 0.92,
  risk_level: "high",
  explanation: {
    summary: "A carteira apresenta múltiplos sinais de risco, incluindo recebimento de fundos de endereços em blacklist e movimentações características de mixers.",
    details: "Foram identificadas 7 transações de valor idêntico em sequência, além de cluster de 5 wallets conectadas entre si em menos de 1 hora. 3 dessas wallets possuem histórico de fraude reportado em bases públicas."
  },
  suspicious_connections: [
    {
      wallet: "4D9x...Kq2P",
      risk: "high",
      reason: "Conexão direta com mixer identificado",
      txCount: 6
    },
    {
      wallet: "8nX7...w9Qv",
      risk: "medium",
      reason: "Recebeu fundos de endereço em blacklist",
      txCount: 2
    },
    {
      wallet: "2JQz...p6Lt",
      risk: "low",
      reason: "Transação com exchange não verificada",
      txCount: 1
    }
  ],
  network_graph: {}, // dados do grafo real — por enquanto placeholder
  events: [
    {
      type: "blacklist",
      date: "2025-07-30 21:14",
      text: "Recebimento de 12 SOL de endereço em blacklist"
    },
    {
      type: "mixer",
      date: "2025-07-30 22:01",
      text: "Transferência para mixer detectado"
    },
    {
      type: "cluster",
      date: "2025-07-31 08:24",
      text: "Cluster de 5 wallets conectadas em menos de 1h"
    },
    {
      type: "exchange",
      date: "2025-07-31 09:18",
      text: "Envio para exchange não verificada"
    }
  ],
  suspicious_transactions: [
    {
      hash: "9Txw7R...bg6eL",
      from: "7fq...4Q2L",
      to: "4D9x...Kq2P",
      value: 4.2,
      time: "2025-07-31 10:23",
      reason: "Recebido de wallet em blacklist"
    },
    {
      hash: "8Ji2nA...g9KLe",
      from: "3fP...7TsQ",
      to: "SUA_WALLET",
      value: 11,
      time: "2025-07-30 20:04",
      reason: "Valor idêntico a outras 3 transações recentes"
    }
  ]
};

export default function ResultsTest() {
  return (
    <div className="relative min-h-screen flex flex-col gap-6 items-center justify-start py-12 px-3">
      {/* Background animado */}
      <ThreeBackground />
      <div className="max-w-5xl w-full mx-auto z-10 relative">
        {/* Cabeçalho de risco */}
        <ResultHeader score={resultData.risk_score} level={resultData.risk_level} />

        {/* Explicação "humana" da IA */}
        <AIExplanation
          summary={resultData.explanation.summary}
          details={resultData.explanation.details}
        />

        {/* Ligações/conexões suspeitas */}
        <SuspiciousConnections connections={resultData.suspicious_connections} />

        {/* Visualização do grafo (placeholder, depois integra o real) */}
        <NetworkGraph data={resultData.network_graph} />

        {/* Timeline dos eventos relevantes */}
        <TimelineEvents events={resultData.events} />

        {/* Tabela de transações suspeitas */}
        <SuspiciousTxList transactions={resultData.suspicious_transactions} />

        {/* Botão de exportar relatório */}
        <div className="flex justify-end">
          <ExportButton data={resultData} />
        </div>
      </div>
    </div>
  );
}
