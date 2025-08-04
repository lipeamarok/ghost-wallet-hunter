import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

// Garanta as fontes e cores personalizadas no Tailwind

export default function HomeHero() {
  const [currentTextIndex, setCurrentTextIndex] = useState(0);

  const rotatingTexts = [
    <>Analyze <span className="font-semibold text-blue-accent">any Solana wallet</span> for suspicious activity.</>,
    <>Lightning-fast <span className="font-semibold text-green-safe">AI forensics</span> & cluster detection.</>,
    <>No registration, <span className="font-semibold text-purple-400">fully private.</span></>,
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTextIndex((prev) => (prev + 1) % rotatingTexts.length);
    }, 3700);
    return () => clearInterval(interval);
  }, []);

  return (
    <section className="w-full flex flex-col items-center justify-center pt-10 sm:pt-20 pb-2 px-2 select-none">
      <div className="w-full max-w-3xl flex flex-col items-center relative">
        {/* Blur Glow BG: independente, NÃO dentro do h1 */}
        <div
          aria-hidden
          className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[580px] h-[120px] sm:w-[800px] sm:h-[150px]
            bg-gradient-to-br from-purple-500 via-fuchsia-500 to-blue-900 blur-2xl opacity-30 pointer-events-none"
          style={{ zIndex: 1 }}
        />

        {/* Título principal, completamente opaco e por cima do blur */}
        <motion.h1
          className="relative z-10 text-center whitespace-nowrap text-[2.15rem] sm:text-4xl md:text-5xl font-bold font-['JetBrains Mono'] tracking-tight
            drop-shadow-[0_2px_22px_rgba(30,130,246,0.33)] mb-4"
          style={{
            letterSpacing: '0.005em',
            textShadow: '0 4px 24px #1e5fff55, 0 0 70px #0009',
          }}
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.18, duration: 1 }}
        >
          <span className="font-extrabold text-gray-100">AI Detectives for{' '}</span>
          <span className="bg-gradient-to-r from-[#8C52FF] via-[#6C21FF] to-[#00FFA3] bg-clip-text text-transparent font-extrabold">
            Solana
          </span>{' '}
          <span className="font-extrabold text-gray-100">Wallets</span>
        </motion.h1>

        {/* Subtítulo rotativo */}
        <motion.div
          className="relative h-8 flex items-center justify-center w-full"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.33, duration: 0.6 }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={currentTextIndex}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.4, ease: "anticipate" }}
              className="flex items-center justify-center w-full"
            >
              <span className="text-sm sm:text-base md:text-lg text-center font-inter text-gray-300 drop-shadow-[0_1px_7px_#1224]">
                {rotatingTexts[currentTextIndex]}
              </span>
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </div>
    </section>
  );
}
