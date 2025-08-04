// src/components/results/ExportButton.jsx
import React from "react";

export default function ExportButton({ data = {}, className = "" }) {
  // Exporta como arquivo JSON
  function exportJSON() {
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "wallet_investigation.json";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 6000);
  }

  // Compartilhamento "link" (ajuste conforme sua infra)
  function shareAnalysis() {
    // Exemplo: copiar link da página (ajuste para um link real de relatório, se houver)
    navigator.clipboard.writeText(window.location.href);
    alert("Link do relatório copiado!");
  }

  return (
    <div className={`flex flex-row gap-3 mt-4 ${className}`}>
      <button
        className="px-4 py-2 rounded-lg bg-blue-600 text-white font-semibold hover:bg-blue-700 shadow transition"
        onClick={exportJSON}
      >
        Exportar JSON
      </button>
      <button
        className="px-4 py-2 rounded-lg bg-blue-800 text-blue-100 font-semibold hover:bg-blue-900 shadow transition"
        onClick={shareAnalysis}
      >
        Compartilhar análise
      </button>
    </div>
  );
}
