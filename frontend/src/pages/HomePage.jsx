// src/pages/HomePage.jsx
import React from "react";
import ThreeBackground from "../components/Background/ThreeBackground";
import HomeHero from "../components/Home/HomeHero";
import WalletInput from "../components/Home/WalletInput";
import PrivacyFooter from "../components/Home/PrivacyFooter";

export default function HomePage() {
  return (
    <div className="min-h-screen w-full bg-navy text-white font-inter relative overflow-hidden">
      {/* Background 3D */}
      <ThreeBackground />

      {/* Overlay escura para contraste */}
      <div className="absolute inset-0 bg-navy/80 z-0 pointer-events-none" />

      {/* Container central */}
      <main className="relative z-10 flex flex-col items-center justify-center min-h-screen px-4 py-8">
        <div className="w-full max-w-4xl mx-auto space-y-8">

          {/* Hero Section - Logo e título */}
          <HomeHero />

          {/* Wallet Input com exemplo integrado */}
          <WalletInput />

          {/* Privacy Footer */}
          <PrivacyFooter />

        </div>
      </main>
    </div>
  );
}
