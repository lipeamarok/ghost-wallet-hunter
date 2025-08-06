import React from "react";
import ThreeBackground from "../components/Background/ThreeBackground";

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen relative flex flex-col items-center justify-center">
      <ThreeBackground />
      <div className="relative z-10 max-w-2xl mx-auto bg-black/80 backdrop-blur-md rounded-xl p-8 mt-12 shadow-2xl border border-gray-800">
        <h1 className="text-3xl font-bold text-blue-400 mb-6">
          Privacy Policy
        </h1>
        <p className="text-gray-200 mb-4">
          At Ghost Wallet Hunter, your privacy and security are our top priority. We do not collect, store, or share any sensitive personal information, private keys, wallet seeds, or credentials. All blockchain investigations are performed using only public Solana data.
        </p>
        <p className="text-gray-400 mb-4">
          <strong>No tracking:</strong> We do not use cookies, advertising pixels, or any form of personal tracking. Your browsing and investigations remain fully anonymous.
        </p>
        <p className="text-gray-400 mb-4">
          <strong>How we use your data:</strong> Wallet addresses and analysis requests are used strictly for performing on-demand blockchain investigations. No addresses or results are stored after your session ends.
        </p>
        <p className="text-gray-400 mb-4">
          <strong>Third-party APIs:</strong> We use public blockchain RPC nodes and open AI models. No personal information is ever shared with these providers.
        </p>
        <p className="text-gray-400 mb-4">
          <strong>Open Source:</strong> Our codebase and analysis logic are fully open source and available on{" "}
          <a
            href="https://github.com/lipeamarok/ghost-wallet-hunter.git"
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-300 underline hover:text-blue-500"
          >
            GitHub
          </a>
          . You are welcome to review or contribute.
        </p>
        <p className="text-gray-500 text-xs mt-6">
          For questions or concerns, please contact us via GitHub. By using Ghost Wallet Hunter, you agree to this policy.
        </p>
      </div>
    </div>
  );
}
