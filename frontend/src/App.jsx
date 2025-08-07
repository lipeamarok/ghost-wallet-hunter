/**
 * Ghost Wallet Hunter - Main App Component
 * =======================================
 *
 * Root application component integrating the complete clean architecture
 * with routing, state management, and error handling.
 */

import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { Toaster } from 'react-hot-toast';

// Configuration and Types
import { ENVIRONMENT } from './config/environment.js';
import { INVESTIGATION_STATUS } from './types/investigation.types.js';

// Hooks and Services
import { useAPI } from './hooks/useAPI.js';
import { useWebSocket } from './hooks/useWebSocket.js';

// Utils
import { getErrorMessage } from './utils/helpers.js';

// Import CSS
import './index.css';

// React Query client (matching original configuration)
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

// Error Boundary Component (custom implementation)
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('App Error Boundary:', error, errorInfo);

    // In production, you might want to send this to an error reporting service
    if (ENVIRONMENT.NODE_ENV === 'production') {
      // Example: Sentry.captureException(error);
    }

    if (this.props.onError) {
      this.props.onError(error, errorInfo);
    }
  }

  render() {
    if (this.state.hasError) {
      if (this.props.FallbackComponent) {
        return <this.props.FallbackComponent
          error={this.state.error}
          resetErrorBoundary={() => {
            this.setState({ hasError: false, error: null });
            if (this.props.onReset) {
              this.props.onReset();
            }
          }}
        />;
      }

      return <ErrorFallback
        error={this.state.error}
        resetErrorBoundary={() => {
          this.setState({ hasError: false, error: null });
          window.location.reload();
        }}
      />;
    }

    return this.props.children;
  }
}

// Error Fallback Component
const ErrorFallback = ({ error, resetErrorBoundary }) => (
  <div className="min-h-screen w-full bg-navy text-white flex items-center justify-center">
    <div className="text-center p-8 max-w-md">
      <div className="text-6xl mb-4">⚠️</div>
      <h1 className="text-2xl font-bold mb-4 text-ghost-accent">
        Oops! Something went wrong
      </h1>
      <p className="text-gray-300 mb-6 leading-relaxed">
        {getErrorMessage(error)}
      </p>
      <button
        onClick={resetErrorBoundary}
        className="px-6 py-3 bg-ghost-accent hover:bg-ghost-accent/80
                   text-navy font-semibold rounded-lg transition-colors duration-200"
      >
        Try Again
      </button>
    </div>
  </div>
);

// Loading Component
const LoadingSpinner = () => (
  <div className="min-h-screen w-full bg-navy text-white flex items-center justify-center">
    <div className="text-center">
      <div className="animate-spin text-6xl mb-4">🔍</div>
      <h2 className="text-xl font-semibold text-ghost-accent mb-2">
        Ghost Wallet Hunter
      </h2>
      <p className="text-gray-400">Loading detective systems...</p>
    </div>
  </div>
);

// Service Status Component
const ServiceStatus = () => {
  const { isLoading, error, data: healthStatus } = useAPI('/health/status', {
    refreshInterval: 30000, // Check every 30 seconds
    revalidateOnFocus: false
  });

  const { isConnected: wsConnected } = useWebSocket();

  if (isLoading || !healthStatus) return null;

  const allServicesOnline = healthStatus.backend && healthStatus.a2a && healthStatus.julia;

  return (
    <div className="fixed top-4 right-4 z-50">
      <div className={`
        px-3 py-2 rounded-lg text-sm font-medium flex items-center space-x-2
        ${allServicesOnline && wsConnected
          ? 'bg-green-900/80 text-green-100 border border-green-700/50'
          : 'bg-red-900/80 text-red-100 border border-red-700/50'
        }
      `}>
        <div className={`
          w-2 h-2 rounded-full
          ${allServicesOnline && wsConnected ? 'bg-green-400' : 'bg-red-400'}
        `} />
        <span>
          {allServicesOnline && wsConnected ? 'All Systems Online' : 'Service Issues Detected'}
        </span>
      </div>
    </div>
  );
};

// Lazy load pages for better performance
const HomePage = lazy(() => import('./pages/HomePage.jsx'));
const InvestigationPage = lazy(() => import('./pages/InvestigationPage.jsx'));
const ResultsPage = lazy(() => import('./pages/ResultsPage.jsx'));
const AboutPage = lazy(() => import('./pages/AboutPage.jsx'));

// 404 Not Found Component
const NotFoundPage = () => (
  <div className="min-h-screen w-full bg-navy text-white flex items-center justify-center">
    <div className="text-center p-8 max-w-md">
      <div className="text-6xl mb-4">👻</div>
      <h1 className="text-2xl font-bold mb-4 text-ghost-accent">
        Page Not Found
      </h1>
      <p className="text-gray-300 mb-6 leading-relaxed">
        The page you're looking for has vanished into the blockchain void.
      </p>
      <a
        href="/"
        className="inline-block px-6 py-3 bg-ghost-accent hover:bg-ghost-accent/80
                   text-navy font-semibold rounded-lg transition-colors duration-200"
      >
        Return to Home
      </a>
    </div>
  </div>
);

// Main App Component
const App = () => {
  // Global app state and initialization
  const [appInitialized, setAppInitialized] = React.useState(false);
  const [appError, setAppError] = React.useState(null);

  // Initialize app services
  React.useEffect(() => {
    const initializeApp = async () => {
      try {
        // Check if we're in development mode
        if (ENVIRONMENT.NODE_ENV === 'development') {
          console.log('🚀 Ghost Wallet Hunter - Development Mode');
          console.log('📊 Environment:', {
            backend: ENVIRONMENT.BACKEND_URL,
            a2a: ENVIRONMENT.A2A_URL,
            julia: ENVIRONMENT.JULIA_URL,
            websocket: ENVIRONMENT.WEBSOCKET_URL
          });
        }

        // Perform any necessary app initialization
        // This could include checking authentication, loading user preferences, etc.

        setAppInitialized(true);
      } catch (error) {
        console.error('App initialization error:', error);
        setAppError(error);
      }
    };

    initializeApp();
  }, []);

  // Show error state if app failed to initialize
  if (appError) {
    return (
      <ErrorFallback
        error={appError}
        resetErrorBoundary={() => {
          setAppError(null);
          setAppInitialized(false);
          // Trigger re-initialization
          window.location.reload();
        }}
      />
    );
  }

  // Show loading state while initializing
  if (!appInitialized) {
    return <LoadingSpinner />;
  }

  return (
    <QueryClientProvider client={queryClient}>
      <ErrorBoundary
        FallbackComponent={ErrorFallback}
        onError={(error, errorInfo) => {
          console.error('App Error Boundary:', error, errorInfo);

          // In production, you might want to send this to an error reporting service
          if (ENVIRONMENT.NODE_ENV === 'production') {
            // Example: Sentry.captureException(error);
          }
        }}
        onReset={() => {
          // Reset any global state if needed
          window.location.reload();
        }}
      >
        <Router
          future={{
            v7_startTransition: true,
            v7_relativeSplatPath: true
          }}
        >
          <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
            {/* Global Service Status Indicator */}
            <ServiceStatus />

            {/* Main Application Routes */}
            <Suspense fallback={<LoadingSpinner />}>
              <Routes>
                {/* Home Page - Investigation Start */}
                <Route
                  path="/"
                  element={<HomePage />}
                />

                {/* Investigation Page - Real-time Monitoring */}
                <Route
                  path="/investigation/:investigationId"
                  element={<InvestigationPage />}
                />

                <Route
                  path="/investigation"
                  element={<InvestigationPage />}
                />

                {/* Results Page - Analysis Display */}
                <Route
                  path="/results/:investigationId"
                  element={<ResultsPage />}
                />

                <Route
                  path="/results"
                  element={<ResultsPage />}
                />

                {/* About Page - Platform Information */}
                <Route
                  path="/about"
                  element={<AboutPage />}
                />

                {/* Legacy Routes - Redirect to new structure */}
                <Route
                  path="/home"
                  element={<Navigate to="/" replace />}
                />

                <Route
                  path="/dashboard"
                  element={<Navigate to="/" replace />}
                />

                <Route
                  path="/analysis/:id"
                  element={<Navigate to="/results/:id" replace />}
                />

                <Route
                  path="/analysis"
                  element={<Navigate to="/" replace />}
                />

                {/* 404 Catch-all */}
                <Route
                  path="*"
                  element={<NotFoundPage />}
                />
              </Routes>
            </Suspense>

            {/* Toast Notifications (matching original setup) */}
            <Toaster
              position="top-right"
              toastOptions={{
                duration: 4000,
                style: {
                  background: '#1f2937',
                  color: '#f9fafb',
                  border: '1px solid #374151',
                },
              }}
            />
          </div>
        </Router>
      </ErrorBoundary>
    </QueryClientProvider>
  );
};

// Export with development helpers
export default App;

// Development helpers
if (ENVIRONMENT.NODE_ENV === 'development') {
  // Make some utilities globally available for debugging
  window.GHOST_DEBUG = {
    ENVIRONMENT,
    INVESTIGATION_STATUS,
    version: '2.0.0-clean-arch'
  };
}
