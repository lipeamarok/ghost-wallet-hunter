// src/components/results/AIExplanation.jsx
import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export default function AIExplanation({
  summary = "Detectamos padrões típicos de clusters e múltiplas conexões com endereços potencialmente ligados a mixers.",
  details = "A carteira analisada recebeu fundos de pelo menos três fontes em blacklist nas últimas 72 horas, e realizou transações de valor idêntico para outros 4 endereços. O padrão se assemelha a operações de ocultação de origem de fundos (mixers). Cluster de 7 carteiras conectadas entre si em menos de 24 horas."
}) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="bg-[#101a2bdd] border-l-4 border-blue-400 px-6 py-5 rounded-xl shadow-md mb-2 transition-all">
      <div className="text-base text-gray-100 font-medium flex items-center gap-2">
        <span className="text-blue-300 font-bold">🤖 AI:</span> {summary}
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
            {details}
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onClick={() => setExpanded(e => !e)}
        className="mt-2 text-blue-400 hover:text-blue-300 underline text-xs font-mono transition"
      >
        {expanded ? "Ocultar detalhes" : "Ver detalhes"}
      </button>
    </div>
  );
}
