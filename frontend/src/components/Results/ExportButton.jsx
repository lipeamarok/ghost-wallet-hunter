// src/components/results/ExportButton.jsx
import React from "react";

export default function ExportButton({ data, className = "" }) {
  const safeData = data || {};
  // Export as JSON file
  function exportJSON() {
    const blob = new Blob([JSON.stringify(safeData, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "wallet_investigation.json";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1500);
  }

  // Share "link" (adjust according to your infra)
  function shareAnalysis() {
    if (typeof navigator?.clipboard?.writeText === 'function') {
      navigator.clipboard.writeText(window.location.href);
      // Optionally could switch to toast system
      alert("Link copied.");
    }
  }

  return (
    <div className={`flex flex-row gap-3 mt-4 ${className}`}>
      <button
        className="px-4 py-2 rounded-lg bg-blue-600 text-white font-semibold hover:bg-blue-700 shadow transition disabled:opacity-40"
        onClick={exportJSON}
        disabled={!Object.keys(safeData).length}
      >
        Export JSON
      </button>
      <button
        className="px-4 py-2 rounded-lg bg-blue-800 text-blue-100 font-semibold hover:bg-blue-900 shadow transition"
        onClick={shareAnalysis}
      >
        Share analysis
      </button>
    </div>
  );
}
