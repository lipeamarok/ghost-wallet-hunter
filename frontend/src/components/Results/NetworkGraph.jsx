// src/components/results/NetworkGraph.jsx
import React from "react";

export default function NetworkGraph({ data }) {
  if (!data || !data.nodes || data.nodes.length === 0) {
    return (
      <div className="w-full h-[300px] md:h-[360px] rounded-2xl border border-blue-900/30 flex items-center justify-center bg-[#0b1a2c]">
        <div className="text-blue-300/60 text-sm font-mono">No connection graph available.</div>
      </div>
    );
  }
  // Real graph implementation placeholder hook - integrate library later.
  return (
    <div className="w-full h-[300px] md:h-[360px] rounded-2xl border border-blue-900/30 bg-[#0b1a2c] relative overflow-hidden">
      {/* Render nodes/edges when implemented */}
      <div className="absolute inset-0 flex items-center justify-center text-blue-300/60 font-mono text-xs">
        Graph: {data.nodes.length} nodes / {data.edges?.length || 0} edges
      </div>
    </div>
  );
}
