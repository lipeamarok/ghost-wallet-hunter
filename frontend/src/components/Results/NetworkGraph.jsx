// src/components/results/NetworkGraph.jsx
import React from "react";

export default function NetworkGraph({ data }) {
  // Substitua depois pelo seu componente real de grafo!
  return (
    <div className="w-full h-[370px] md:h-[420px] bg-gradient-to-br from-[#19273d] to-[#0b1a2c] rounded-2xl shadow-inner border border-blue-900/30 flex items-center justify-center my-6">
      <div className="text-blue-300/70 font-mono text-lg text-center select-none">
        [ Visualização de conexões será exibida aqui ]<br />
        <span className="text-gray-500 text-xs">
          (network graph interativo, clique para explorar clusters)
        </span>
      </div>
    </div>
  );
}
