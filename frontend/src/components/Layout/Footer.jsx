import React from 'react';
import { motion } from 'framer-motion';

const Footer = () => {
  return (
    <motion.footer 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="bg-gray-900 border-t border-gray-800 py-8"
    >
      <div className="max-w-7xl mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* System Info */}
          <div>
            <h3 className="text-lg font-mono font-bold text-cyan-400 mb-4">
              [SYSTEM_INFO]
            </h3>
            <div className="space-y-2 text-sm font-mono">
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> VERSION: v2.0.0
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> BUILD: {new Date().getFullYear()}.{(new Date().getMonth() + 1).toString().padStart(2, '0')}.{new Date().getDate().toString().padStart(2, '0')}
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> STATUS: OPERATIONAL
              </div>
            </div>
          </div>

          {/* Legal */}
          <div>
            <h3 className="text-lg font-mono font-bold text-cyan-400 mb-4">
              [LEGAL_FRAMEWORK]
            </h3>
            <div className="space-y-2 text-sm font-mono">
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> FOR EDUCATIONAL USE ONLY
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> BLOCKCHAIN FORENSICS RESEARCH
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> NOT FINANCIAL ADVICE
              </div>
            </div>
          </div>

          {/* Tech Stack */}
          <div>
            <h3 className="text-lg font-mono font-bold text-cyan-400 mb-4">
              [TECH_STACK]
            </h3>
            <div className="space-y-2 text-sm font-mono">
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> REACT: 18.x
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> AI: OPENAI + GROK
              </div>
              <div className="text-gray-400">
                <span className="text-green-400">&gt;</span> CHAIN: SOLANA
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-gray-800 mt-8 pt-6">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="text-gray-500 font-mono text-xs mb-4 md:mb-0">
              © {new Date().getFullYear()} GHOST WALLET HUNTER - BLOCKCHAIN INTELLIGENCE PLATFORM
            </div>
            <div className="flex items-center space-x-4 text-xs font-mono">
              <div className="text-green-400">SYSTEM_STATUS: ONLINE</div>
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            </div>
          </div>
        </div>
      </div>
    </motion.footer>
  );
};

export default Footer;
