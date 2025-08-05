// src/pages/ResultsComboTest.jsx
import React, { useState } from "react";
import BlockchainTravel from "../components/Loading/BlockchainTravel";
import ArrivalTransition from "../components/Transitions/ArrivalTransition";
import ResultsBackground from "../components/Background/ResultsBackground";

export default function ResultsComboTest() {
  const [step, setStep] = useState(0);

  // step 0 = viagem | 1 = transição de pouso | 2 = resultado
  React.useEffect(() => {
    if (step === 0) {
      // Após 3.7s de viagem, ativa a transição de chegada (ajuste o tempo para o que preferir!)
      const t = setTimeout(() => setStep(1), 3700);
      return () => clearTimeout(t);
    }
  }, [step]);

  return (
    <div className="relative min-h-screen flex items-center justify-center">
      {step === 0 && <BlockchainTravel />}
      {step >= 1 && <ResultsBackground />}
      {step === 1 && (
        <ArrivalTransition onFinish={() => setStep(2)} />
      )}

      {/* Resultado */}
      {step === 2 && (
        <div className="relative z-20 flex flex-col items-center justify-center min-h-screen">
          <h1 className="text-4xl font-bold text-white mb-4 drop-shadow-lg">
            Investigation Results
          </h1>
          <p className="text-lg text-blue-200 font-mono">
            (Results content goes here!)
          </p>
        </div>
      )}
    </div>
  );
}
