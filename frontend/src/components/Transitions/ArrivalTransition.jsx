// src/components/Transitions/ArrivalTransition.jsx
import React, { useEffect, useRef } from "react";

export default function ArrivalTransition({ onFinish, duration = 1400 }) {
  const overlayRef = useRef();

  useEffect(() => {
    // Efeito flash + radial blur
    let start = null;
    function animate(ts) {
      if (!start) start = ts;
      const progress = Math.min((ts - start) / duration, 1);

      // Radial gradient vai fechando o túnel
      if (overlayRef.current) {
        overlayRef.current.style.opacity = Math.max(0, 1 - progress * 1.3);
        overlayRef.current.style.backdropFilter = `blur(${10 + progress * 32}px)`;
        overlayRef.current.style.background =
          `radial-gradient(circle at 50% 55%, rgba(120,180,255,${0.6 - progress * 0.4}) 0%, rgba(10, 37, 64, 0.98) 90%)`;
      }

      // Flash final (opcional)
      if (progress > 0.92 && overlayRef.current) {
        overlayRef.current.style.background = `rgba(220,245,255,${(progress - 0.92) * 10})`;
        overlayRef.current.style.backdropFilter = `blur(40px)`;
      }

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else if (onFinish) {
        setTimeout(onFinish, 80);
      }
    }
    requestAnimationFrame(animate);
  }, [onFinish, duration]);

  return (
    <div
      ref={overlayRef}
      className="fixed inset-0 z-50 pointer-events-none transition-all duration-1000"
      style={{
        opacity: 1,
        backdropFilter: "blur(10px)",
        background:
          "radial-gradient(circle at 50% 55%, rgba(120,180,255,0.6) 0%, rgba(10, 37, 64, 0.98) 90%)"
      }}
    />
  );
}
