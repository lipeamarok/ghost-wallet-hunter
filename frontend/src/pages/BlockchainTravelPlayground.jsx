// src/pages/BlockchainTravelPlayground.jsx
import BlockchainTravel from '../components/Loading/BlockchainTravel';
import React from 'react';

export default function BlockchainTravelPlayground() {
  return (
    <div className="min-h-screen bg-black flex items-center justify-center">
      <BlockchainTravel />
      <div className="absolute bottom-10 w-full flex justify-center">
        <div className="bg-black/70 px-6 py-3 rounded-lg shadow-md text-gray-200 font-mono text-sm">
          Testando animação 3D — ajuste o BlockchainTravel.jsx à vontade!
        </div>
      </div>
    </div>
  );
}
