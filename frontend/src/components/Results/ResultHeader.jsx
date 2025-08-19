// src/components/results/ResultHeader.jsx
import React from "react";
import clsx from "clsx";

export default function ResultHeader({ score, level }) {
  // Derive score normalization (accept 0-100 or 0-1)
  const numeric = typeof score === 'number' ? (score > 1 ? score / 100 : score) : null;
  const safeScore = numeric !== null ? Math.max(0, Math.min(1, numeric)) : null;

  // Derive level if not provided
  let derivedLevel = level;
  if (!derivedLevel && safeScore !== null) {
    derivedLevel = safeScore >= 0.8 ? 'high' : safeScore >= 0.5 ? 'medium' : 'low';
  }

  const levelMap = {
    low: { color: "bg-green-500", label: "Low Risk" },
    medium: { color: "bg-yellow-400", label: "Medium Risk" },
    high: { color: "bg-red-600", label: "High Risk" }
  };
  const { color, label } = levelMap[derivedLevel] || { color: "bg-gray-600", label: "No Score" };

  return (
    <div className="flex items-center gap-6 py-6 px-4 rounded-xl shadow-xl bg-gradient-to-br from-[#0a2540bb] via-[#131e2ecc] to-[#221a2e99] border border-blue-900/30">
      <div className={clsx("w-16 h-16 flex items-center justify-center rounded-full text-3xl font-black", color)}>
        {derivedLevel === 'high' ? '🚨' : derivedLevel === 'medium' ? '⚠️' : derivedLevel === 'low' ? '🟢' : 'ℹ️'}
      </div>
      <div>
        <div className="text-lg font-semibold text-gray-200 tracking-wide">{label}</div>
        <div className="mt-1 flex items-center gap-2">
          <div className="w-40 h-3 bg-gray-700/40 rounded">
            <div
              className={clsx(
                "h-3 rounded transition-all",
                derivedLevel === 'high' ? 'bg-red-500' : derivedLevel === 'medium' ? 'bg-yellow-400' : derivedLevel === 'low' ? 'bg-green-400' : 'bg-gray-500'
              )}
              style={{ width: safeScore !== null ? `${Math.round(safeScore * 100)}%` : '0%' }}
            />
          </div>
          <span className="text-sm text-gray-400 font-mono">{safeScore !== null ? `${Math.round(safeScore * 100)}%` : '--'}</span>
        </div>
      </div>
    </div>
  );
}
