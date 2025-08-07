/**
 * Ghost Wallet Hunter - Pages Index
 * =================================
 *
 * Centralized export for all page components.
 * Provides unified access to the entire pages layer.
 */

// Main page components
export { default as HomePage } from './HomePage.jsx';
export { default as InvestigationPage } from './InvestigationPage.jsx';
export { default as ResultsPage } from './ResultsPage.jsx';
export { default as AboutPage } from './AboutPage.jsx';

// Page routing configuration
export const pageRoutes = [
  {
    path: '/',
    component: 'HomePage',
    name: 'Home',
    description: 'Main landing page with investigation starter'
  },
  {
    path: '/investigation/:investigationId',
    component: 'InvestigationPage',
    name: 'Investigation',
    description: 'Real-time investigation monitoring and progress tracking'
  },
  {
    path: '/results/:investigationId',
    component: 'ResultsPage',
    name: 'Results',
    description: 'Investigation results with detailed analysis and export'
  },
  {
    path: '/about',
    component: 'AboutPage',
    name: 'About',
    description: 'Platform information, features, and system status'
  }
];

// Default export with all pages
export default {
  HomePage: () => import('./HomePage.jsx'),
  InvestigationPage: () => import('./InvestigationPage.jsx'),
  ResultsPage: () => import('./ResultsPage.jsx'),
  AboutPage: () => import('./AboutPage.jsx')
};
