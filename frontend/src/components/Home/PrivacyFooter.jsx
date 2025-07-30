import React from 'react';
import { motion } from 'framer-motion';
import { ShieldCheckIcon, CodeBracketIcon, EyeSlashIcon } from '@heroicons/react/24/outline';

export default function PrivacyFooter() {
  return (
    <motion.footer
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 1.4, duration: 0.8 }}
      className="text-center space-y-4"
    >
      {/* Main privacy message */}
      <div className="flex items-center justify-center space-x-6 text-sm text-gray-400">
        <div className="flex items-center space-x-2">
          <EyeSlashIcon className="w-4 h-4 text-blue-accent" />
          <span>100% private</span>
        </div>

        <div className="flex items-center space-x-2">
          <ShieldCheckIcon className="w-4 h-4 text-green-safe" />
          <span>Powered by JuliaOS</span>
        </div>

        <div className="flex items-center space-x-2">
          <CodeBracketIcon className="w-4 h-4 text-purple-400" />
          <span>Open-source</span>
        </div>
      </div>

      {/* Additional links */}
      <div className="flex items-center justify-center space-x-6 text-xs text-gray-500">
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
    </motion.footer>
  );
}
