// src/components/results/SuspiciousTxList.jsx
import React from "react";

export default function SuspiciousTxList({ transactions }) {
  const txs = (transactions || []).filter(Boolean);
  if (txs.length === 0) {
    return (
      <div className="w-full my-6 rounded-xl bg-[#101a2b88] p-4 border border-blue-900/30">
        <div className="font-bold text-gray-200 mb-2">🔎 Suspicious Transactions</div>
        <div className="text-xs text-gray-500">No suspicious transactions identified.</div>
      </div>
    );
  }
  const copy = txt => navigator.clipboard.writeText(txt);
  const openSolscan = hash => window.open(`https://solscan.io/tx/${hash}`, "_blank");
  return (
    <div className="w-full my-6 overflow-x-auto rounded-xl bg-[#101a2b88] p-2">
      <div className="font-bold text-gray-200 mb-2">🔎 Suspicious Transactions</div>
      <table className="w-full min-w-[580px] text-left">
        <thead>
          <tr className="text-blue-300/80 text-xs">
            <th className="py-1 px-2 font-semibold">Tx Hash</th>
            <th className="py-1 px-2 font-semibold">From</th>
            <th className="py-1 px-2 font-semibold">To</th>
            <th className="py-1 px-2 font-semibold">Value (SOL)</th>
            <th className="py-1 px-2 font-semibold">Date/Time</th>
            <th className="py-1 px-2 font-semibold">Reason</th>
            <th className="py-1 px-2"></th>
          </tr>
        </thead>
        <tbody>
          {txs.map((tx, i) => (
            <tr key={i} className="border-b border-blue-950/60 hover:bg-blue-900/20 text-sm transition">
              <td className="py-1 px-2 font-mono">
                <span className="underline cursor-pointer" onClick={() => openSolscan(tx.hash)}>{tx.hash}</span>
              </td>
              <td className="py-1 px-2 font-mono">
                {tx.from}
                <button className="ml-1 text-xs text-gray-400 hover:text-blue-400" title="Copy"
                  onClick={() => copy(tx.from)}>⧉</button>
              </td>
              <td className="py-1 px-2 font-mono">
                {tx.to}
                <button className="ml-1 text-xs text-gray-400 hover:text-blue-400" title="Copy"
                  onClick={() => copy(tx.to)}>⧉</button>
              </td>
              <td className="py-1 px-2">{tx.value}</td>
              <td className="py-1 px-2 text-xs text-gray-400">{tx.time}</td>
              <td className="py-1 px-2 text-gray-200">{tx.reason}</td>
              <td className="py-1 px-2">
                <button
                  className="text-blue-300 hover:text-blue-500 underline text-xs"
                  onClick={() => openSolscan(tx.hash)}
                  title="View on Solscan"
                >Solscan</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
