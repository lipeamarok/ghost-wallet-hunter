import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { Toaster } from 'react-hot-toast';

import Layout from './components/Layout/Layout';
import HomePage from './pages/HomePage';
import AnalysisPage from './pages/AnalysisPage';
import ResultsPage from './pages/ResultsPage';
import ResultsTest from './pages/ResultsTest'; // Importando a página de teste
import AboutPage from './pages/AboutPage';
import AnalysisPageSimple from './pages/AnalysisPageSimple';
import ResultsPageSimple from './pages/ResultsPageSimple';
import BlockchainTravelPlayground from './pages/BlockchainTravelPlayground';
import TransitionTest from './pages/TransitionTest';
import ResultsComboTest from './pages/ResultsComboTest';

// NOVAS PÁGINAS FINAIS
import Analysis from './pages/Analysis';
import Results from './pages/Results';

import './index.css';

// React Query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router
        future={{
          v7_startTransition: true,
          v7_relativeSplatPath: true
        }}
      >
        <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
          <Routes>
            {/* HomePage sem Layout - página de entrada limpa */}
            <Route path="/" element={<HomePage />} />

            {/* PÁGINAS FINAIS DE PRODUÇÃO */}
            <Route path="/analysis" element={<Analysis />} />
            <Route path="/results" element={<Results />} />

            {/* Páginas simples sem Layout - investigação rápida */}
            <Route path="/analysis-simple" element={<AnalysisPageSimple />} />
            <Route path="/results-simple" element={<ResultsPageSimple />} />

            {/* Outras páginas com Layout (com Header) - ANTIGAS */}
            <Route path="/analysis-old" element={<Layout><AnalysisPage /></Layout>} />
            <Route path="/results-old/:walletAddress" element={<Layout><ResultsPage /></Layout>} />
            <Route path="/about" element={<Layout><AboutPage /></Layout>} />

            {/* Página de teste 3D */}
            <Route path="/3d-test" element={<BlockchainTravelPlayground />} />
            {/* Página de transição */}
            <Route path="/transition-test" element={<TransitionTest />} />
            {/* Rota de loading */}
            <Route path="/loading" element={<Layout><BlockchainTravelPlayground /></Layout>} />
            {/* Página de teste de resultados */}
            <Route path="/results-test" element={<Layout><ResultsTest /></Layout>} />
            {/* Página de teste de combo de resultados */}
            <Route path="/results-combo-test" element={<Layout><ResultsComboTest /></Layout>} />

          </Routes>
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
    </QueryClientProvider>
  );
}

export default App;
