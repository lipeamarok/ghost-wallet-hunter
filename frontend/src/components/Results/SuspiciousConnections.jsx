// src/components/results/SuspiciousConnections.jsx
import React from "react";

const riskColor = {
  high: "border-red-500 bg-red-900/30",
  medium: "border-yellow-400 bg-yellow-800/20",
  low: "border-green-400 bg-green-900/20"
};

export default function SuspiciousConnections({ connections }) {
  const list = (connections || []).filter(Boolean);
  if (list.length === 0) {
    return (
      <div className="my-5 rounded-xl border border-blue-900/30 p-4 bg-gray-800/30">
        <div className="font-bold text-gray-200 mb-1">🔗 Suspicious Connections</div>
        <div className="text-xs text-gray-500">No suspicious connections identified.</div>
      </div>
    );
  }
  return (
    <div className="my-5 grid grid-cols-1 md:grid-cols-3 gap-5">
      {list.map((conn, i) => (
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
              {conn.risk === "high" ? "High risk" : conn.risk === "medium" ? "Medium risk" : "Low risk"}
            </span>
          </div>
          <div className="text-gray-300 text-sm mt-1">{conn.reason}</div>
          <div className="text-xs text-gray-400 mt-1">Transactions: {conn.txCount}</div>
        </div>
      ))}
    </div>
  );
}
