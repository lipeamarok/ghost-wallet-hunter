import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const IntelligencePanel = ({ investigationData, walletAddress, isAnalyzing, currentPhase }) => {
  const [revealedSections, setRevealedSections] = useState([]);
  const [typewriterText, setTypewriterText] = useState('');
  const [currentSection, setCurrentSection] = useState(0);

  const intelligenceReport = generateIntelligenceReport(investigationData, walletAddress);

  useEffect(() => {
    if (currentPhase >= 4) { // Phase 4: Generating intelligence report
      // Progressive section reveal
      intelligenceReport.forEach((section, index) => {
        setTimeout(() => {
          setRevealedSections(prev => [...prev, index]);
        }, index * 1000);
      });
    }
  }, [currentPhase, intelligenceReport]);

  // Typewriter effect for current section
  useEffect(() => {
    if (revealedSections.length > 0) {
      const currentIndex = revealedSections[revealedSections.length - 1];
      const text = intelligenceReport[currentIndex]?.content || '';

      let index = 0;
      setTypewriterText('');

      const timer = setInterval(() => {
        setTypewriterText(text.slice(0, index));
        index++;

        if (index > text.length) {
          clearInterval(timer);
        }
      }, 30);

      return () => clearInterval(timer);
    }
  }, [revealedSections, intelligenceReport]);

  if (currentPhase < 4) {
    return (
      <div className="bg-gray-900 border border-gray-700 rounded-lg p-6">
        <div className="text-gray-500 font-mono text-center">
          Intelligence report pending...
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-900 border border-gray-700 rounded-lg overflow-hidden">
      {/* Header */}
      <div className="bg-black border-b border-gray-700 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-green-400 font-mono text-lg font-bold">
              BLOCKCHAIN INTELLIGENCE REPORT
            </h2>
            <div className="text-gray-400 text-sm font-mono">
              Classification: TACTICAL | Generated: {new Date().toISOString()}
            </div>
          </div>
          <div className="text-cyan-400 font-mono text-2xl animate-pulse">
            [ACTIVE]
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6 space-y-6 max-h-[500px] overflow-y-auto">
        <AnimatePresence>
          {intelligenceReport.map((section, index) => (
            revealedSections.includes(index) && (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5 }}
                className="border-l-2 border-cyan-400 pl-4"
              >
                <div className="text-cyan-400 font-mono text-sm font-bold mb-2">
                  {section.title}
                </div>
                <div className="text-gray-300 font-mono text-sm leading-relaxed">
                  {index === revealedSections[revealedSections.length - 1] ?
                    typewriterText : section.content}
                  {index === revealedSections[revealedSections.length - 1] &&
                   typewriterText.length < section.content.length && (
                    <span className="text-green-400 animate-pulse">█</span>
                  )}
                </div>
              </motion.div>
            )
          ))}
        </AnimatePresence>

        {/* Risk Assessment Metrics */}
        {revealedSections.length >= 3 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.5 }}
            className="bg-black border border-gray-600 rounded-lg p-4 mt-6"
          >
            <div className="text-yellow-400 font-mono text-sm font-bold mb-3">
              THREAT ASSESSMENT MATRIX
            </div>
            <div className="grid grid-cols-2 gap-4">
              <ThreatMetric
                label="Risk Score"
                value={investigationData?.results?.risk_assessment?.risk_score || 0}
                max={1}
                color="text-red-400"
              />
              <ThreatMetric
                label="Confidence"
                value={investigationData?.results?.risk_assessment?.confidence || 0.85}
                max={1}
                color="text-cyan-400"
              />
              <ThreatMetric
                label="Connections"
                value={investigationData?.results?.connections?.length || 0}
                max={20}
                color="text-yellow-400"
              />
              <ThreatMetric
                label="Blacklist Match"
                value={investigationData?.blacklist_alert?.is_blacklisted ? 1 : 0}
                max={1}
                color="text-red-500"
                isBoolean
              />
            </div>
          </motion.div>
        )}

        {/* Action Recommendations */}
        {revealedSections.length >= 4 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 1 }}
            className="bg-gradient-to-r from-red-900/20 to-yellow-900/20 border border-yellow-600/50 rounded-lg p-4"
          >
            <div className="text-yellow-400 font-mono text-sm font-bold mb-3 flex items-center">
              <span className="w-2 h-2 bg-yellow-400 rounded-full animate-pulse mr-2"></span>
              OPERATIONAL RECOMMENDATIONS
            </div>
            <div className="space-y-2 text-gray-300 font-mono text-sm">
              {getRecommendations(investigationData).map((rec, index) => (
                <div key={index} className="flex items-start">
                  <span className="text-yellow-400 mr-2">▶</span>
                  {rec}
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
};

const ThreatMetric = ({ label, value, max, color, isBoolean = false }) => {
  const percentage = isBoolean ? (value ? 100 : 0) : (value / max) * 100;

  return (
    <div>
      <div className="flex justify-between text-xs mb-1">
        <span className="text-gray-400">{label}</span>
        <span className={color}>
          {isBoolean ? (value ? 'POSITIVE' : 'NEGATIVE') : `${(value * 100).toFixed(1)}%`}
        </span>
      </div>
      <div className="w-full bg-gray-700 rounded-full h-2">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 1, delay: 0.5 }}
          className={`h-2 rounded-full ${
            percentage > 70 ? 'bg-red-500' :
            percentage > 40 ? 'bg-yellow-500' :
            'bg-green-500'
          }`}
        />
      </div>
    </div>
  );
};

const generateIntelligenceReport = (data, walletAddress) => {
  const riskLevel = data?.results?.risk_assessment?.risk_level || 'unknown';
  const isBlacklisted = data?.blacklist_alert?.is_blacklisted || false;
  const connections = data?.results?.connections?.length || 0;

  return [
    {
      title: '[1] TARGET IDENTIFICATION',
      content: `Subject wallet ${walletAddress} has been processed through our blockchain forensics pipeline. Initial classification indicates ${riskLevel.toUpperCase()} risk profile with ${connections} detected network connections.`
    },
    {
      title: '[2] BLACKLIST ANALYSIS',
      content: isBlacklisted ?
        `CRITICAL: Target is flagged in multiple threat intelligence databases. This wallet has been associated with fraudulent activities, scams, or other malicious behaviors. Immediate caution advised.` :
        `Target wallet not found in current threat intelligence databases. No direct associations with known malicious entities detected in our blacklist verification systems.`
    },
    {
      title: '[3] BEHAVIORAL ANALYSIS',
      content: `Transaction pattern analysis reveals ${riskLevel === 'high' ? 'irregular behaviors consistent with evasion tactics' : riskLevel === 'medium' ? 'some anomalous patterns requiring monitoring' : 'standard wallet usage patterns'}. Network topology mapping shows ${connections} direct relationships with varying risk assessments.`
    },
    {
      title: '[4] THREAT ASSESSMENT',
      content: `Overall risk classification: ${riskLevel.toUpperCase()}. ${isBlacklisted ? 'High priority due to blacklist match.' : 'Assessment based on behavioral patterns and network analysis.'} Confidence level indicates reliable intelligence for operational decision-making.`
    }
  ];
};

const getRecommendations = (data) => {
  const riskLevel = data?.results?.risk_assessment?.risk_level || 'unknown';
  const isBlacklisted = data?.blacklist_alert?.is_blacklisted || false;

  if (isBlacklisted) {
    return [
      'AVOID ALL TRANSACTIONS with this wallet address',
      'Report wallet to relevant authorities if involved in fraud',
      'Monitor for any indirect connections to your wallets',
      'Update security protocols if previously interacted'
    ];
  }

  switch (riskLevel) {
    case 'high':
      return [
        'Exercise extreme caution before any interactions',
        'Implement additional verification procedures',
        'Monitor wallet for continued suspicious activity',
        'Consider transaction limits if interaction necessary'
      ];
    case 'medium':
      return [
        'Proceed with standard security protocols',
        'Verify transaction details carefully',
        'Monitor for unusual patterns',
        'Document interactions for compliance'
      ];
    default:
      return [
        'Standard security protocols sufficient',
        'Maintain normal operational procedures',
        'Periodic monitoring recommended',
        'Follow standard compliance requirements'
      ];
  }
};

export default IntelligencePanel;
