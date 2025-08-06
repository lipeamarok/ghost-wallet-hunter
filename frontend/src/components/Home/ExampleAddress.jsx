import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

// Lista com apenas endereços CONFIRMADOS do próprio projeto
// Fontes: Verificados no código do Ghost Wallet Hunter
const SUSPICIOUS_ADDRESSES = [
  "3RH44Pfx9GtN8ZWoSdWHoxH7HqXAC7V3YcqkX3kDf8J4",
  "AVvCiPrjR3es4NHnA4HrUXVsYFbyeasDBzWhywH7pCtC",
  "GmCYGAzMHhsNgoSK8JKHNRpdXC4xsbmFy9fknMioAmEK",
  "EHPGHGnFVYMZhc9xHF597yHC19odPHP6Kn2nmvkkWCWk",
  "7tCSWUZYKRvx1obdFB6hwFJRN7gFEadE3dFX4fsJ1nPz",
  "218JtpiEn5ZUvMoLwPmZtXf7ZM6PvMXvrmYuw6ZaoeB1",
  "8qezdtS9eP3GvSuFdYd11cLB84pD8siwjBvTqyBxfxKk",
  "4qzye6MmnyFkLKGq2yM64QpUgv3TyefwwR9zHrS6LThb",
  "Fxm4yyVLSuWGhKNyJtr93VA6feJkjTjirTca78vpUVFe",
  "5C9EHpAdSNBFWboWs9HHGy2kZ4CJCkxCHW8fFRhVcZLx",
  "CEzN7mqP9xoxn2HdyW6fjEJ73t7qaX9Rp2zyS6hb3iEu",
  "Htp9MGP8Tig923ZFY7Qf2zzbMUmYneFRAhSp7vSg4wxV",
  "5WwBYgQG6BdErM2nNNyUmQXfcUnB68b6kesxBywh1J3n",
  "GeEccGJ9BEzVbVor1njkBCCiqXJbXVeDHaXDCrBDbmuy",
  "GVbyCuPaLqox4GxhJSQkETkeyS2aom8T2QJkFpzxafSn",
  "22KbNKB1qHraWbJGFzBhcYRSNTPi7grBAMQQWDY6Tmo1",
  "3ohzhq5tE29KpQAacEHXKVfkThxZE8iYLra1A3Aa9eCJ",
  "F49Zg4ZAXX8ipvKyvPvidGCkfqE88XMFz8BVow8MFKi2",
  "BcTGFE7CxFyg13tfCU54BZJrT98BAHWxjQNuMgxnUnbJ",
  "FfCS2nm1yRBiGSTZUTpfFjcm1gyAe4CeekmG9eKQLEXY",
  "8dYUoKezvHRthevi2tyegKjYce44X5ZSYPtBsKJxERbk",
  "64HGPXsiAFgWhQWDpET6KHheXKgD3XLo4aG4GyMHDPm6",
  "GznziHLRYoszY8DoW3y3gtRkVM1Z2oyS34EXcbBddJiS",
  "B8Y1dERnVNoUUXeXA4NaCHiB9htcukMSkfHrFsTMHA7h",
  "MszS2N8CT1MV9byX8FKFnrUpkmASSeR5Fmji19ushw1",
];

export default function ExampleAddress({ onAddressSelect }) {
  const [currentAddress, setCurrentAddress] = useState('');

  const getRandomAddress = () => {
    const randomIndex = Math.floor(Math.random() * SUSPICIOUS_ADDRESSES.length);
    return SUSPICIOUS_ADDRESSES[randomIndex];
  };

  // Set random address on mount and change it every 10 seconds
  useEffect(() => {
    setCurrentAddress(getRandomAddress());
    const interval = setInterval(() => {
      setCurrentAddress(getRandomAddress());
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  const handleUseExample = () => {
    if (onAddressSelect) {
      onAddressSelect(currentAddress);
    }
  };

  return (
    <motion.div
      className="flex items-center justify-center space-x-2 text-sm"
      key={currentAddress} // Force re-render on address change
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
    >
      <span className="text-gray-500">Example:</span>

      <motion.button
        onClick={handleUseExample}
        className="font-mono text-xs text-blue-accent hover:text-blue-300 transition-colors px-2 py-1 rounded bg-white/5 hover:bg-white/10"
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        title="Click to test this suspicious address"
      >
        <span>{currentAddress}</span>
      </motion.button>

      <span className="text-red-200 text-xs">(suspicious)</span>
    </motion.div>
  );
}
