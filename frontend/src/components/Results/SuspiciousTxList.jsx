// src/components/results/SuspiciousTxList.jsx
import React from "react";

export default function SuspiciousTxList({
  transactions = [
    {
      hash: "9Txw7R...bg6eL",
      from: "7fq...4Q2L",
      to: "6sk...8JbR",
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
}) {
  const copy = txt => navigator.clipboard.writeText(txt);
  const openSolscan = hash => window.open(`https://solscan.io/tx/${hash}`, "_blank");
  return (
    <div className="w-full my-6 overflow-x-auto rounded-xl bg-[#101a2b88] p-2">
      <div className="font-bold text-gray-200 mb-2">🔎 Transações Suspeitas</div>
      <table className="w-full min-w-[580px] text-left">
        <thead>
          <tr className="text-blue-300/80 text-xs">
            <th className="py-1 px-2 font-semibold">Tx Hash</th>
            <th className="py-1 px-2 font-semibold">De</th>
            <th className="py-1 px-2 font-semibold">Para</th>
            <th className="py-1 px-2 font-semibold">Valor (SOL)</th>
            <th className="py-1 px-2 font-semibold">Data/Hora</th>
            <th className="py-1 px-2 font-semibold">Motivo</th>
            <th className="py-1 px-2"></th>
          </tr>
        </thead>
        <tbody>
          {transactions.map((tx, i) => (
            <tr key={i} className="border-b border-blue-950/60 hover:bg-blue-900/20 text-sm transition">
              <td className="py-1 px-2 font-mono">
                <span className="underline cursor-pointer" onClick={() => openSolscan(tx.hash)}>{tx.hash}</span>
              </td>
              <td className="py-1 px-2 font-mono">
                {tx.from}
                <button className="ml-1 text-xs text-gray-400 hover:text-blue-400" title="Copiar"
                  onClick={() => copy(tx.from)}>⧉</button>
              </td>
              <td className="py-1 px-2 font-mono">
                {tx.to}
                <button className="ml-1 text-xs text-gray-400 hover:text-blue-400" title="Copiar"
                  onClick={() => copy(tx.to)}>⧉</button>
              </td>
              <td className="py-1 px-2">{tx.value}</td>
              <td className="py-1 px-2 text-xs text-gray-400">{tx.time}</td>
              <td className="py-1 px-2 text-gray-200">{tx.reason}</td>
              <td className="py-1 px-2">
                <button
                  className="text-blue-300 hover:text-blue-500 underline text-xs"
                  onClick={() => openSolscan(tx.hash)}
                  title="Ver no Solscan"
                >Solscan</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
