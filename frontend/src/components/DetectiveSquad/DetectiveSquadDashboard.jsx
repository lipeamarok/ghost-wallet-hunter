import React, { useState, useEffect } from 'react';
import { useQuery } from 'react-query';
import { motion, AnimatePresence } from 'framer-motion';
import {
  UserGroupIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  ClockIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline';

import { detectiveService } from '../../services/detectiveAPI';
import LoadingSpinner from '../UI/LoadingSpinner';
import DetectiveCard from './DetectiveCard';

const DetectiveSquadDashboard = ({ onDetectiveSelect, selectedDetectives = [] }) => {
  const [squadStats, setSquadStats] = useState({
    totalCases: 0,
    successRate: 0,
    avgResponseTime: 0
  });

  // Fetch squad status
  const {
    data: squadStatus,
    isLoading,
    error,
    refetch
  } = useQuery(
    'squadStatus',
    detectiveService.getSquadStatus,
    {
      refetchInterval: 30000, // Refetch every 30 seconds
      onSuccess: (data) => {
        // Calculate squad statistics
        if (data?.detectives) {
          const totalCases = data.detectives.reduce((sum, det) => sum + det.cases_solved, 0);
          const avgSuccess = data.detectives.reduce((sum, det) => sum + det.success_rate, 0) / data.detectives.length;

          setSquadStats({
            totalCases,
            successRate: avgSuccess,
            avgResponseTime: 2.3 // Mock for now
          });
        }
      }
    }
  );

  const getHealthColor = (health) => {
    switch (health) {
      case 'excellent': return 'text-green-500';
      case 'good': return 'text-blue-500';
      case 'degraded': return 'text-yellow-500';
      case 'critical': return 'text-red-500';
      default: return 'text-gray-500';
    }
  };

  const getHealthIcon = (health) => {
    switch (health) {
      case 'excellent':
      case 'good':
        return <ShieldCheckIcon className="h-5 w-5" />;
      case 'degraded':
      case 'critical':
        return <ExclamationTriangleIcon className="h-5 w-5" />;
      default:
        return <ClockIcon className="h-5 w-5" />;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8">
        <LoadingSpinner />
        <span className="ml-3 text-gray-600">Loading Detective Squad...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6">
        <div className="flex items-center">
          <ExclamationTriangleIcon className="h-6 w-6 text-red-500 mr-3" />
          <div>
            <h3 className="font-semibold text-red-800">Squad Connection Error</h3>
            <p className="text-red-600 mt-1">{error.message}</p>
            <button
              onClick={() => refetch()}
              className="mt-2 px-3 py-1 bg-red-600 text-white rounded text-sm hover:bg-red-700"
            >
              Retry Connection
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Squad Status Header */}
      <div className="bg-white rounded-lg shadow-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center">
            <UserGroupIcon className="h-8 w-8 mr-3 text-blue-600" />
            Legendary Detective Squad
          </h2>
          <div className={`flex items-center ${getHealthColor(squadStatus?.squad_health)}`}>
            {getHealthIcon(squadStatus?.squad_health)}
            <span className="ml-2 font-semibold capitalize">
              {squadStatus?.squad_health || 'Unknown'}
            </span>
          </div>
        </div>

        {/* Squad Statistics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-blue-50 rounded-lg p-4">
            <div className="flex items-center">
              <UserGroupIcon className="h-8 w-8 text-blue-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-blue-600">Active Detectives</p>
                <p className="text-2xl font-bold text-blue-900">
                  {squadStatus?.active_detectives || 0} / {squadStatus?.total_detectives || 7}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-green-50 rounded-lg p-4">
            <div className="flex items-center">
              <ChartBarIcon className="h-8 w-8 text-green-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-green-600">Cases Solved</p>
                <p className="text-2xl font-bold text-green-900">{squadStats.totalCases}</p>
              </div>
            </div>
          </div>

          <div className="bg-purple-50 rounded-lg p-4">
            <div className="flex items-center">
              <ShieldCheckIcon className="h-8 w-8 text-purple-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-purple-600">Success Rate</p>
                <p className="text-2xl font-bold text-purple-900">
                  {squadStats.successRate.toFixed(1)}%
                </p>
              </div>
            </div>
          </div>

          <div className="bg-orange-50 rounded-lg p-4">
            <div className="flex items-center">
              <ClockIcon className="h-8 w-8 text-orange-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-orange-600">Avg Response</p>
                <p className="text-2xl font-bold text-orange-900">
                  {squadStats.avgResponseTime}s
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Last Updated */}
        <p className="text-sm text-gray-500">
          Last updated: {squadStatus?.last_updated
            ? new Date(squadStatus.last_updated).toLocaleString()
            : 'Unknown'
          }
        </p>
      </div>

      {/* Detective Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        <AnimatePresence>
          {squadStatus?.detectives?.map((detective, index) => (
            <motion.div
              key={detective.code_name}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ delay: index * 0.1 }}
            >
              <DetectiveCard
                detective={detective}
                onSelect={onDetectiveSelect}
                isSelected={selectedDetectives.includes(detective.code_name)}
                showStats={true}
              />
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Empty State */}
      {(!squadStatus?.detectives || squadStatus.detectives.length === 0) && (
        <div className="text-center py-12">
          <UserGroupIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No detectives available</h3>
          <p className="mt-1 text-sm text-gray-500">
            The detective squad is currently offline. Please try again later.
          </p>
          <button
            onClick={() => refetch()}
            className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Refresh Squad
          </button>
        </div>
      )}
    </div>
  );
};

export default DetectiveSquadDashboard;
