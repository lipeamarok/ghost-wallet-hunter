// frontend/src/components/Transitions/ArrivalTransition.jsx
import React, { useEffect, useState } from "react";

/**
 * ArrivalTransition: Um flash radial cinematográfico + glow
 * Props:
 *  - show: boolean (se a transição está ativa)
 *  - onFinish: function (callback quando animação termina)
 */
export default function ArrivalTransition({ show, onFinish }) {
  const [visible, setVisible] = useState(show);

  useEffect(() => {
    if (show) {
      setVisible(true);
      const timeout = setTimeout(() => {
        setVisible(false);
        if (onFinish) onFinish();
      }, 1200); // duração total da animação
      return () => clearTimeout(timeout);
    }
  }, [show, onFinish]);

  // Só renderiza quando ativo (evita "piscar" ao ocultar)
  if (!visible && !show) return null;

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center pointer-events-none"
      style={{
        background: "radial-gradient(circle at 50% 54%, #fff 10%, #6de0ff 34%, #0e1831 75%)",
        opacity: show ? 1 : 0,
        transition: "opacity 800ms cubic-bezier(.7, .06, .34, 1)",
        filter: show
          ? "blur(0px) brightness(1.1) saturate(1.3)"
          : "blur(20px) brightness(2) saturate(1.6)",
      }}
    >
      {/* Glow central expandindo */}
      <div
        style={{
          width: show ? "130vw" : "0vw",
          height: show ? "130vw" : "0vw",
          background:
            "radial-gradient(circle, rgba(255,255,255,0.9) 0%, rgba(108,223,255,0.20) 55%, transparent 80%)",
          filter: "blur(4px)",
          borderRadius: "100%",
          transition: "all 1.05s cubic-bezier(.55, .16, .39, 1.01)",
          position: "absolute",
          left: "50%",
          top: "54%",
          transform: "translate(-50%, -50%)",
          zIndex: 2,
        }}
      />
      {/* Pulso leve na borda */}
      <div
        style={{
          width: show ? "100vw" : "0vw",
          height: show ? "100vw" : "0vw",
          borderRadius: "100%",
          border: show
            ? "5vw solid rgba(110,224,255,0.12)"
            : "0vw solid transparent",
          transition: "all 0.85s cubic-bezier(.49, .02, .47, 1.09)",
          position: "absolute",
          left: "50%",
          top: "54%",
          transform: "translate(-50%, -50%)",
          zIndex: 1,
        }}
      />
      {/* Flash rápido no centro */}
      <div
        style={{
          width: show ? "38vw" : "0vw",
          height: show ? "38vw" : "0vw",
          background: "radial-gradient(circle, #fff 0%, #fff0 80%)",
          filter: "blur(9px)",
          borderRadius: "100%",
          opacity: show ? 0.85 : 0,
          transition: "all 420ms cubic-bezier(.83, .11, .52, 1.11)",
          position: "absolute",
          left: "50%",
          top: "54%",
          transform: "translate(-50%, -50%)",
          zIndex: 4,
        }}
      />
    </div>
  );
}
