import React from 'react';
import UniversalHeader from './HeaderUniversal';
import Footer from './Footer';

const Layout = ({ children }) => {
  return (
    <div className="min-h-screen flex flex-col bg-black text-green-400">
      <UniversalHeader />
      <main className="flex-1">
        {children}
      </main>
    </div>
  );
};

export default Layout;
