// src/components/results/SuspiciousConnections.jsx
import React from "react";

const riskColor = {
  high: "border-red-500 bg-red-900/30",
  medium: "border-yellow-400 bg-yellow-800/20",
  low: "border-green-400 bg-green-900/20"
};

export default function SuspiciousConnections({
  connections = [
    {
      wallet: "6f3...Qx9k",
      risk: "high",
      reason: "Transferência direta de mixer detectado",
      txCount: 4
    },
    {
      wallet: "9qL...r4r8",
      risk: "medium",
      reason: "Recebeu 2x fundos de endereço em blacklist",
      txCount: 2
    },
    {
      wallet: "4xX...p9Nq",
      risk: "low",
      reason: "Transação cruzada com exchange não verificada",
      txCount: 1
    }
  ]
}) {
  return (
    <div className="my-5 grid grid-cols-1 md:grid-cols-3 gap-5">
      {connections.map((conn, i) => (
        <div
          key={i}
          className={`rounded-xl border shadow-lg p-4 flex flex-col gap-1 ${riskColor[conn.risk] || "border-gray-700 bg-gray-800/30"}`}
        >
          <div className="flex items-center gap-2">
            <span className="font-mono text-sm text-blue-200">{conn.wallet}</span>
            <span className="text-xs rounded px-2 py-0.5 ml-auto"
              style={{
                background: conn.risk === "high" ? "#dc2626aa" : conn.risk === "medium" ? "#eab308aa" : "#22c55eaa",
                color: "#fff"
              }}
            >
              {conn.risk === "high" ? "Risco alto" : conn.risk === "medium" ? "Risco médio" : "Risco baixo"}
            </span>
          </div>
          <div className="text-gray-300 text-sm mt-1">{conn.reason}</div>
          <div className="text-xs text-gray-400 mt-1">Transações: {conn.txCount}</div>
        </div>
      ))}
    </div>
  );
}
