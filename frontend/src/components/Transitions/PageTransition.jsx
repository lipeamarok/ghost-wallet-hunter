import { motion, AnimatePresence } from "framer-motion";
import React from "react";

export default function PageTransition({ show }) {
  return (
    <AnimatePresence>
      {show && (
        <motion.div
          className="fixed inset-0 z-[90] flex items-center justify-center pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.8 }}
        >
          {/* Sutil: overlay azul escuro e radial */}
          <div className="absolute inset-0"
            style={{
              background: "radial-gradient(ellipse at 50% 55%, rgba(34,45,72,0.73) 0%, rgba(8,16,26,0.87) 60%, #000 100%)",
              backdropFilter: "blur(3.5px)"
            }}
          />
          {/* Sutil animação de texto */}
          <motion.div
            className="relative z-10"
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            transition={{ duration: 0.6, delay: 0.23 }}
          >
            <span className="text-xl md:text-3xl font-bold text-blue-200 drop-shadow">
              investigating...
            </span>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
