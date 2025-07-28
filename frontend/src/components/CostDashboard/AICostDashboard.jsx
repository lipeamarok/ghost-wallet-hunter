import React from 'react';
import { useQuery } from 'react-query';
import { motion } from 'framer-motion';
import { 
  CurrencyDollarIcon, 
  ChartBarIcon, 
  UsersIcon, 
  ClockIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

import { costService } from '../../services/detectiveAPI';
import LoadingSpinner from '../UI/LoadingSpinner';

const AICostDashboard = ({ userId = 'frontend_user' }) => {
  // Fetch cost dashboard data
  const { data: dashboard, isLoading: dashboardLoading } = useQuery(
    'costDashboard',
    costService.getDashboard,
    {
      refetchInterval: 30000, // Refresh every 30 seconds
    }
  );

  // Fetch user usage data
  const { data: userUsage, isLoading: usageLoading } = useQuery(
    ['userUsage', userId],
    () => costService.getUserUsage(userId),
    {
      refetchInterval: 10000, // Refresh every 10 seconds
    }
  );

  // Fetch providers status
  const { data: providersStatus } = useQuery(
    'providersStatus',
    costService.getProvidersStatus,
    {
      refetchInterval: 30000,
    }
  );

  const isLoading = dashboardLoading || usageLoading;

  // Colors for pie chart
  const COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444'];

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 4
    }).format(amount);
  };

  const getProviderStatusColor = (status) => {
    switch (status) {
      case 'active': return 'text-green-500 bg-green-100';
      case 'fallback': return 'text-yellow-500 bg-yellow-100';
      case 'disabled': return 'text-red-500 bg-red-100';
      default: return 'text-gray-500 bg-gray-100';
    }
  };

  const getProviderStatusIcon = (status) => {
    switch (status) {
      case 'active': return <CheckCircleIcon className="h-4 w-4" />;
      case 'fallback': return <ExclamationTriangleIcon className="h-4 w-4" />;
      case 'disabled': return <ExclamationTriangleIcon className="h-4 w-4" />;
      default: return <ClockIcon className="h-4 w-4" />;
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8">
        <LoadingSpinner />
        <span className="ml-3 text-gray-600">Loading cost dashboard...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <CurrencyDollarIcon className="h-8 w-8 mr-3 text-green-600" />
          AI Cost Dashboard
        </h2>
        <div className="text-sm text-gray-500">
          Last updated: {new Date().toLocaleTimeString()}
        </div>
      </div>

      {/* User Usage Summary */}
      {userUsage && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white rounded-lg shadow-lg p-6">
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-8 w-8 text-green-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-green-600">Daily Spent</p>
                <p className="text-2xl font-bold text-green-900">
                  {formatCurrency(userUsage.daily_cost)}
                </p>
                <p className="text-xs text-gray-500">
                  Limit: {formatCurrency(userUsage.limits.daily_budget)}
                </p>
              </div>
            </div>
            <div className="mt-3">
              <div className="bg-gray-200 rounded-full h-2">
                <div 
                  className="bg-green-600 h-2 rounded-full"
                  style={{ 
                    width: `${Math.min((userUsage.daily_cost / userUsage.limits.daily_budget) * 100, 100)}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6">
            <div className="flex items-center">
              <ChartBarIcon className="h-8 w-8 text-blue-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-blue-600">Requests Today</p>
                <p className="text-2xl font-bold text-blue-900">
                  {userUsage.requests_today}
                </p>
                <p className="text-xs text-gray-500">
                  Limit: {userUsage.limits.requests_per_day}
                </p>
              </div>
            </div>
            <div className="mt-3">
              <div className="bg-gray-200 rounded-full h-2">
                <div 
                  className="bg-blue-600 h-2 rounded-full"
                  style={{ 
                    width: `${Math.min((userUsage.requests_today / userUsage.limits.requests_per_day) * 100, 100)}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6">
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-8 w-8 text-purple-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-purple-600">Monthly Spent</p>
                <p className="text-2xl font-bold text-purple-900">
                  {formatCurrency(userUsage.monthly_cost)}
                </p>
                <p className="text-xs text-gray-500">
                  Limit: {formatCurrency(userUsage.limits.monthly_budget)}
                </p>
              </div>
            </div>
            <div className="mt-3">
              <div className="bg-gray-200 rounded-full h-2">
                <div 
                  className="bg-purple-600 h-2 rounded-full"
                  style={{ 
                    width: `${Math.min((userUsage.monthly_cost / userUsage.limits.monthly_budget) * 100, 100)}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-lg p-6">
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-8 w-8 text-orange-600" />
              <div className="ml-3">
                <p className="text-sm font-medium text-orange-600">Total Spent</p>
                <p className="text-2xl font-bold text-orange-900">
                  {formatCurrency(userUsage.total_cost)}
                </p>
                <p className="text-xs text-gray-500">All time</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Global Dashboard Stats */}
      {dashboard && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white rounded-lg shadow-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Global Usage</h3>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Total Cost:</span>
                <span className="font-semibold">{formatCurrency(dashboard.total_cost)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Total Requests:</span>
                <span className="font-semibold">{dashboard.total_requests.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Active Users:</span>
                <span className="font-semibold">{dashboard.active_users}</span>
              </div>
            </div>
          </div>

          {/* Provider Status */}
          <div className="bg-white rounded-lg shadow-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">AI Providers</h3>
            <div className="space-y-3">
              {dashboard.cost_by_provider?.map((provider, index) => (
                <div key={provider.provider} className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className={`flex items-center px-2 py-1 rounded-full text-xs font-medium ${getProviderStatusColor(provider.status)}`}>
                      {getProviderStatusIcon(provider.status)}
                      <span className="ml-1 capitalize">{provider.provider}</span>
                    </div>
                  </div>
                  <span className="text-sm font-semibold">
                    {formatCurrency(provider.total_cost)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Cost Breakdown Pie Chart */}
          <div className="bg-white rounded-lg shadow-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Cost by Provider</h3>
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie
                  data={dashboard.cost_by_provider?.map((provider, index) => ({
                    name: provider.provider,
                    value: provider.total_cost,
                    color: COLORS[index % COLORS.length]
                  }))}
                  cx="50%"
                  cy="50%"
                  innerRadius={40}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {dashboard.cost_by_provider?.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => formatCurrency(value)} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Cost Trends Chart */}
      {dashboard?.cost_trends && dashboard.cost_trends.length > 0 && (
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Cost Trends (Last 7 Days)</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={dashboard.cost_trends}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis tickFormatter={formatCurrency} />
              <Tooltip formatter={(value) => formatCurrency(value)} />
              <Area type="monotone" dataKey="cost" stroke="#3B82F6" fill="#3B82F6" fillOpacity={0.3} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Recent Investigations */}
      {dashboard?.recent_investigations && dashboard.recent_investigations.length > 0 && (
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Investigations</h3>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Wallet
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Detectives
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Cost
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Time
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {dashboard.recent_investigations.map((investigation) => (
                  <tr key={investigation.investigation_id}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {investigation.wallet_address.slice(0, 10)}...
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {investigation.detectives_used} detectives
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatCurrency(investigation.cost)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(investigation.timestamp).toLocaleTimeString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default AICostDashboard;
