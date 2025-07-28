import React from 'react';
import { motion } from 'framer-motion';
import { 
  CheckCircleIcon, 
  ExclamationCircleIcon, 
  ClockIcon,
  StarIcon,
  CursorArrowRaysIcon
} from '@heroicons/react/24/outline';

const DetectiveCard = ({ 
  detective, 
  onSelect, 
  isSelected = false, 
  showStats = false,
  className = '' 
}) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return 'text-green-500 bg-green-100';
      case 'busy': return 'text-yellow-500 bg-yellow-100';
      case 'offline': return 'text-red-500 bg-red-100';
      default: return 'text-gray-500 bg-gray-100';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'active': return <CheckCircleIcon className="h-4 w-4" />;
      case 'busy': return <ClockIcon className="h-4 w-4" />;
      case 'offline': return <ExclamationCircleIcon className="h-4 w-4" />;
      default: return <ClockIcon className="h-4 w-4" />;
    }
  };

  const getDetectiveEmoji = (codeName) => {
    const emojiMap = {
      'POIROT': '🕵️',
      'MARPLE': '👵',
      'SPADE': '🚬',
      'MARLOWE': '🔍',
      'DUPIN': '📋',
      'SHADOW': '🌑',
      'RAVEN': '🐦‍⬛'
    };
    return emojiMap[codeName] || '🕵️';
  };

  const handleClick = () => {
    if (onSelect && detective.status === 'active') {
      onSelect(detective);
    }
  };

  return (
    <motion.div
      className={`
        relative bg-white rounded-lg shadow-lg border-2 transition-all duration-200 cursor-pointer
        ${isSelected 
          ? 'border-blue-500 shadow-blue-200 shadow-lg' 
          : 'border-gray-200 hover:border-gray-300 hover:shadow-md'
        }
        ${detective.status !== 'active' ? 'opacity-75' : ''}
        ${className}
      `}
      onClick={handleClick}
      whileHover={{ scale: detective.status === 'active' ? 1.02 : 1 }}
      whileTap={{ scale: detective.status === 'active' ? 0.98 : 1 }}
      layout
    >
      {/* Selection Indicator */}
      {isSelected && (
        <motion.div
          className="absolute -top-2 -right-2 z-10"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", stiffness: 500, damping: 30 }}
        >
          <div className="bg-blue-500 text-white rounded-full p-1">
            <CheckCircleIcon className="h-4 w-4" />
          </div>
        </motion.div>
      )}

      <div className="p-6">
        {/* Header */}
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center">
            <div className="text-3xl mr-3">
              {getDetectiveEmoji(detective.code_name)}
            </div>
            <div>
              <h3 className="text-lg font-bold text-gray-900">
                {detective.name}
              </h3>
              <p className="text-sm text-gray-600 font-medium">
                {detective.code_name}
              </p>
            </div>
          </div>
          
          {/* Status Badge */}
          <div className={`flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(detective.status)}`}>
            {getStatusIcon(detective.status)}
            <span className="ml-1 capitalize">{detective.status}</span>
          </div>
        </div>

        {/* Specialty */}
        <div className="mb-4">
          <p className="text-sm font-semibold text-gray-700 mb-1">Specialty</p>
          <p className="text-sm text-gray-600">{detective.specialty}</p>
        </div>

        {/* Motto */}
        <div className="mb-4">
          <p className="text-xs text-gray-500 italic">
            "{detective.motto}"
          </p>
        </div>

        {/* Stats (if enabled) */}
        {showStats && (
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="text-center">
              <p className="text-lg font-bold text-blue-600">{detective.cases_solved}</p>
              <p className="text-xs text-gray-500">Cases Solved</p>
            </div>
            <div className="text-center">
              <div className="flex items-center justify-center">
                <StarIcon className="h-4 w-4 text-yellow-500 mr-1" />
                <p className="text-lg font-bold text-yellow-600">
                  {detective.success_rate?.toFixed(1) || '0.0'}%
                </p>
              </div>
              <p className="text-xs text-gray-500">Success Rate</p>
            </div>
          </div>
        )}

        {/* Location */}
        <div className="flex items-center justify-between text-xs text-gray-500">
          <span>📍 {detective.location}</span>
          {detective.status === 'active' && onSelect && (
            <div className="flex items-center text-blue-600">
              <CursorArrowRaysIcon className="h-3 w-3 mr-1" />
              <span>Click to select</span>
            </div>
          )}
        </div>

        {/* Unavailable Overlay */}
        {detective.status !== 'active' && (
          <div className="absolute inset-0 bg-gray-100 bg-opacity-50 rounded-lg flex items-center justify-center">
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-600 mb-1">
                {detective.status === 'busy' ? 'Currently Busy' : 'Offline'}
              </p>
              <p className="text-xs text-gray-500">
                {detective.status === 'busy' 
                  ? 'Working on another case' 
                  : 'Not available right now'
                }
              </p>
            </div>
          </div>
        )}
      </div>
    </motion.div>
  );
};

export default DetectiveCard;
