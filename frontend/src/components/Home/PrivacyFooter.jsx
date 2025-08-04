import React from 'react';
import { motion } from 'framer-motion';
import { ShieldCheckIcon } from '@heroicons/react/24/outline';

export default function AppFooter() {
  return (
    <motion.footer
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 1.4, duration: 0.8 }}
      className="fixed bottom-0 left-0 w-full z-50 py-3 bg-transparent"
      style={{
        // Use transparent to mostrar o background que você já usa
        // Troque para 'bg-[#10141a]' se quiser um fundo escuro sólido
        backdropFilter: 'blur(2px)',
      }}
    >
      <div className="flex flex-col items-center justify-center space-y-1">
        {/* Powered by JuliaOS */}
        <div className="flex items-center space-x-2 text-sm text-gray-200">
          <ShieldCheckIcon className="w-5 h-5 text-green-safe" />
          <span>Powered by JuliaOS</span>
        </div>

        {/* Links centralizados abaixo */}
        <div className="flex items-center space-x-6 text-xs text-gray-400 pt-1">
          <motion.a
            href="#"
            className="hover:text-blue-accent transition-colors"
            whileHover={{ scale: 1.05 }}
          >
            Documentation
          </motion.a>
          <span className="text-gray-600">•</span>
          <motion.a
            href="#"
            className="hover:text-blue-accent transition-colors"
            whileHover={{ scale: 1.05 }}
          >
            GitHub
          </motion.a>
          <span className="text-gray-600">•</span>
          <motion.a
            href="#"
            className="hover:text-blue-accent transition-colors"
            whileHover={{ scale: 1.05 }}
          >
            Privacy Policy
          </motion.a>
        </div>
      </div>
    </motion.footer>
  );
}
