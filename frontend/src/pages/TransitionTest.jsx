import React, { useState } from "react";
import PageTransition from "../components/Transitions/PageTransition";
import BlockchainTravel from "../components/Loading/BlockchainTravel";
import ThreeBackground from "../components/Background/ThreeBackground";

export default function TransitionPlayground() {
  const [step, setStep] = useState(0);

  // step 0 = home | 1 = transição | 2 = animação 3D
  const startTransition = () => {
    setStep(1); // ativa transição
    setTimeout(() => setStep(2), 1300); // depois de 1.3s, mostra a animação 3D
  };

  return (
    <div className="relative min-h-screen overflow-hidden">
      <ThreeBackground />

      {step === 0 && (
        <div className="relative z-10 flex flex-col items-center justify-center min-h-screen">
          <h1 className="text-4xl font-bold text-white mb-8 drop-shadow">
            Ghost Wallet Hunter
          </h1>
          <button
            onClick={startTransition}
            className="px-7 py-3 rounded-lg bg-blue-600 text-white text-lg font-semibold shadow-lg hover:bg-blue-700 transition"
          >
            Investigar!
          </button>
        </div>
      )}

      <PageTransition show={step === 1} />

      {step === 2 && <BlockchainTravel />}
    </div>
  );
}
