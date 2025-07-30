import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { HomeIcon, InformationCircleIcon } from '@heroicons/react/24/outline';

const Header = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  const navigationItems = [
    { path: '/', label: 'HOME', icon: HomeIcon },
    { path: '/about', label: 'ABOUT', icon: InformationCircleIcon }
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="border-b border-gray-800 bg-gray-900 sticky top-0 z-50"
    >
      <div className="max-w-7xl mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <div
            className="cursor-pointer group"
            onClick={() => navigate('/')}
          >
            <h1 className="text-2xl font-mono font-bold text-cyan-400 group-hover:text-cyan-300 transition-colors">
              GHOST WALLET HUNTER v2.0
            </h1>
            <p className="text-sm text-gray-400 font-mono">
              Professional Blockchain Intelligence Platform
            </p>
          </div>

          {/* Navigation */}
          <div className="flex items-center space-x-4">
            {navigationItems.map((item) => {
              const Icon = item.icon;
              return (
                <button
                  key={item.path}
                  onClick={() => navigate(item.path)}
                  className={`flex items-center space-x-2 px-4 py-2 rounded font-mono text-sm font-medium transition-all ${
                    isActive(item.path)
                      ? 'bg-cyan-600 text-black'
                      : 'text-gray-400 hover:text-cyan-400 hover:bg-gray-800'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>[{item.label}]</span>
                </button>
              );
            })}
          </div>

          <div className="text-xs text-gray-500 font-mono">
            {new Date().toISOString()}
          </div>
        </div>
      </div>
    </motion.div>
  );
};

export default Header;
