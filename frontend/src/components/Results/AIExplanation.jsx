// src/components/results/AIExplanation.jsx
import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export default function AIExplanation({ summary, details }) {
  const [expanded, setExpanded] = useState(false);
  const safeSummary = summary || "No consolidated summary available.";
  const safeDetails = details || "No additional details provided by the agents.";

  return (
    <div className="bg-[#101a2bdd] border-l-4 border-blue-400 px-6 py-5 rounded-xl shadow-md mb-2 transition-all">
      <div className="text-base text-gray-100 font-medium flex items-center gap-2">
        <span className="text-blue-300 font-bold">🤖 AI:</span> {safeSummary}
      </div>
      <AnimatePresence>
        {expanded && (
          <motion.div
            className="text-gray-300 mt-2 text-sm"
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 6 }}
            transition={{ duration: 0.3 }}
          >
            {safeDetails}
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onClick={() => setExpanded(e => !e)}
        className="mt-2 text-blue-400 hover:text-blue-300 underline text-xs font-mono transition"
      >
        {expanded ? "Hide details" : "Show details"}
      </button>
    </div>
  );
}
