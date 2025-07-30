import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

// Lista com apenas endereços CONFIRMADOS do próprio projeto
// Fontes: Verificados no código do Ghost Wallet Hunter
const SUSPICIOUS_ADDRESSES = [
  "5zMyQtvhSQ8r7P5ki7c19V7XsPmg5wWwLM1m8F2w5nDa",
  "7NUk1UKvANgS3VvTszkVapMCDuTydJLD7yzP93DbmB3o",
  "B1NqAq3X4AGnchLKgGVPSkoGdWj6Z4nFmyBvS7ftxyxg",
  "6v6HSNEnSMb3kxYb9uGEnTXf2oabKiGXqM5f8Jc5Qa5h",
  "5VUnRBtpU4fykUGu4wK6DNwCXVRuJqhwM22WKWbzrvni",
  "Dm3NpkTCSFAPMCcRUfKx28PXtA1kZpN57eozw7wPWwPe",
  "GvG5XUkRYkfxzEuNTr6no1PtjkAv65e6eH1QuH85UbFS",
  "2Tx7p9bSL4txf2us4phc6r8ueT8Z17VExfyc7zj3JGqM",
  "AvhF1Dna8W8yXvgrzE1h6qDCg32HZRaDVq3BzxUPrgGL",
  "Z5F2P2TywNqXz2GkwuV2v4F8uD4yV3jcLALNQMWfFWB",
  "9o4HaJ7RSZ1Su7N9DGEUPgWZMy7PiYbhtCFyKK5ZHKmJ",
  "2tEKbBoZEro9PULaCeKQY8V4iPXn1rVyk1p3TEoE8csi",
  "9e8Dn7t8m7grwCP1EV7SUo2M39KDYkaPoSRo2N5t39J",
  "FpHtGk5Cq3VyP82G1En7wEHKQTVkDbwEDaqrrgMcFDXo",
  "8RMAbQ6sKtrLDZULe3rA1qvtJcJwcLk4mWLqfX3Q4FeY",
  "FwtHQGFfWLctEx6Jaszk4G4nMLHZv5GSK9qFRqWdrWqu",
  "3RbBjhVRi8qYoGB5NLiKEszq2ci559so4nPqv2iNjs8Q",
  "5zMyQtvhSQ8r7P5ki7c19V7XsPmg5wWwLM1m8F2w5nDa",
  "BDUQb8uYDKdo9c5Y9doaPcofEzwzDLT5ZJk7hr8FweAC",
  "4k9EJp9vtf95b4pTnTi5v3fKtTkkhzCDJkaD7Vv2FvGn",
  "7UeJbGRS3iHh6g58xTn6J3oAjq3HG6aRhXpgToVGRmJc",
  "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
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
