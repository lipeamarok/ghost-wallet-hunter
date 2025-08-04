// src/pages/HomePage.jsx
import React from "react";
import ThreeBackground from "../components/Background/ThreeBackground";
import HomeHero from "../components/Home/HomeHero";
import WalletInput from "../components/Home/WalletInput";
import PrivacyFooter from "../components/Home/PrivacyFooter";
import HeaderUniversal from "../components/Layout/HeaderUniversal"; // novo header

export default function HomePage() {
  return (
    <div className="min-h-screen w-full bg-navy text-white font-inter relative overflow-hidden">
      {/* Background 3D */}
      <ThreeBackground />

      {/* Overlay escura para contraste */}
      <div className="absolute inset-0 bg-navy/80 z-0 pointer-events-none" />

      {/* Cabeçalho universal */}
      <HeaderUniversal />

      {/* Container central */}
      <main className="relative z-10 flex flex-col items-center justify-center min-h-screen px-4 py-8">
        <div className="w-full max-w-4xl mx-auto flex flex-col items-center space-y-8">

          {/* Hero Section */}
          <HomeHero />

          {/* Wallet Input centralizado */}
          <div className="w-full flex flex-col items-center justify-center">
            <WalletInput />
          </div>

          {/* Rodapé de privacidade */}
          <PrivacyFooter />

        </div>
      </main>
    </div>
  );
}
