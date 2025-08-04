// src/components/results/ResultHeader.jsx
import React from "react";
import clsx from "clsx";

export default function ResultHeader({ score = 0.87, level = "high" }) {
  // Mapas para cor e label
  const levelMap = {
    low: { color: "bg-green-500", label: "Risco Baixo" },
    medium: { color: "bg-yellow-400", label: "Risco Médio" },
    high: { color: "bg-red-600", label: "Risco Alto" }
  };

  const { color, label } = levelMap[level] || levelMap["medium"];

  return (
    <div className="flex items-center gap-6 py-6 px-4 rounded-xl shadow-xl bg-gradient-to-br from-[#0a2540bb] via-[#131e2ecc] to-[#221a2e99] border border-blue-900/30">
      <div className={clsx("w-16 h-16 flex items-center justify-center rounded-full text-3xl font-black", color)}>
        {level === "high" ? "🚨" : level === "medium" ? "⚠️" : "🟢"}
      </div>
      <div>
        <div className="text-lg font-semibold text-gray-200 tracking-wide">{label}</div>
        <div className="mt-1 flex items-center gap-2">
          <div className="w-40 h-3 bg-gray-700/40 rounded">
            <div
              className={clsx(
                "h-3 rounded transition-all",
                level === "high" ? "bg-red-500" : level === "medium" ? "bg-yellow-400" : "bg-green-400"
              )}
              style={{ width: `${Math.round(score * 100)}%` }}
            />
          </div>
          <span className="text-sm text-gray-400 font-mono">{Math.round(score * 100)}%</span>
        </div>
      </div>
    </div>
  );
}
