import React, { useMemo } from 'react';
import ResultHeader from './ResultHeader.jsx';
import AIExplanation from './AIExplanation.jsx';
import SuspiciousTxList from './SuspiciousTxList.jsx';
import SuspiciousConnections from './SuspiciousConnections.jsx';
import TimelineEvents from './TimelineEvents.jsx';
import NetworkGraph from './NetworkGraph.jsx';
import ExportButton from './ExportButton.jsx';
import DetectiveSquad from './DetectiveSquad.jsx';
import { mapTimelineData } from '../../services/dataMappers.js';

/**
 * UnifiedResultsView
 * Agregates normalized/detailed agent findings into curated UI components.
 * Now includes the Detective Squad component to show real Julia backend results.
 */
export default function UnifiedResultsView({ results }) {
  const { summary = {}, detectives = {}, metadata = {}, rawResults = {} } = results || {};

  console.log('🔍 UnifiedResultsView:', {
    detectivesCount: Object.keys(detectives || {}).length,
    hasSummary: !!summary
  });

  const derived = useMemo(() => {
    // Use new detective structure from mapped data
    const agents = Object.entries(detectives || {});
    let suspiciousTx = [];
    let connections = [];
    let timeline = mapTimelineData(detectives);
    let aiSummary = '';
    let aiDetails = '';

    // Get AI summary from first completed detective
    const completedDetectives = agents.filter(([_, detective]) => detective?.isCompleted);
    if (completedDetectives.length > 0) {
      const [agentName, detective] = completedDetectives[0];
      aiDetails = detective.conclusion || '';
      aiSummary = `${detective.detective} analyzed ${detective.totalTransactions} transactions and classified risk as ${detective.riskLevel?.toLowerCase() || 'unknown'}.`;
    }

    // Extract suspicious transactions from detective analysis
    for (const [agentName, detective] of agents) {
      if (!detective?.isCompleted || !detective.analysis) continue;

      const analysis = detective.analysis;
      const samples = analysis.sample_transactions || [];

      samples.forEach(tx => {
        if (!tx) return;
        const amount = tx.sol_delta || 0;
        const large = amount >= 1000;
        const medium = amount >= 1 && amount < 1000;

        if (tx.direction === 'out' || tx.direction === 'in' || large) {
          suspiciousTx.push({
            hash: tx.signature || tx.hash || 'unknown',
            from: tx.direction === 'in' ? 'Unknown' : 'This Wallet',
            to: tx.direction === 'out' ? 'Unknown' : 'This Wallet',
            value: Number(amount.toFixed(9)),
            time: tx.block_time ? new Date(tx.block_time * 1000).toISOString().replace('T',' ').slice(0,16) : '-',
            reason: large ? 'Large transfer' : medium ? 'Medium transfer' : `Direction: ${tx.direction}`
          });
        }
      });

      // Extract connections
      const linked = analysis.linked_addresses || [];
      linked.forEach(l => {
        if (!l?.address) return;
        const rs = l.relation_score || 0;
        const risk = rs >= 0.5 ? 'high' : rs >= 0.2 ? 'medium' : 'low';
        connections.push({
          wallet: l.address.slice(0,6)+'...'+l.address.slice(-4),
          risk,
          reason: l.relation?.replace('_',' ') || 'linked',
          txCount: l.tx_count || 1
        });
      });

      // Pattern / anomaly events - include more sources
      const anomalySets = [
        analysis.anomaly_detection?.mild_anomalies,
        analysis.threat_evaluation?.low_priority_threats,
        analysis.threat_evaluation?.medium_priority_threats,
        analysis.threat_evaluation?.high_priority_threats,
        analysis.transaction_patterns?.value_anomalies,
        analysis.stealth_analysis?.stealth_patterns,
        analysis.ominous_patterns?.behavioral_prophecies,
        analysis.shadow_networks?.network_threat_level === 'moderate_threat' ? ['Shadow network involvement'] : null
      ].filter(Boolean).flat().filter(Boolean);

      // Add threat count as event if > 0
      if (analysis.threat_evaluation?.threat_count > 0) {
        timeline.push({
          type: 'other',
          date: metadata.completionTime || '-',
          text: `${agentName}: ${analysis.threat_evaluation.threat_count} threat(s) detected`
        });
      }

      anomalySets.slice(0,3).forEach(a => timeline.push({
        type: 'other',
        date: metadata.completionTime || '-',
        text: `${agentName}: ${String(a).slice(0,120)}`
      }));
    }

    // De-duplicate transactions by hash
    const seenTx = new Set();
    suspiciousTx = suspiciousTx.filter(tx => {
      if (seenTx.has(tx.hash)) return false;
      seenTx.add(tx.hash);
      return true;
    }).slice(0,25);
    connections = connections.slice(0,12);
    timeline = timeline.slice(0,12);

    if (!aiSummary) aiSummary = 'Aggregated multi-agent assessment.';
    if (!aiDetails) aiDetails = 'Nenhum detalhe textual consolidado fornecido pelos agentes.';

    return { suspiciousTx, connections, timeline, aiSummary, aiDetails };
  }, [detectives, metadata]);

  const level = summary.riskScore >= 80 ? 'high' : summary.riskScore >= 50 ? 'medium' : 'low';
  const scoreNorm = (summary.riskScore || 0)/100; // ResultHeader expects 0-1

  return (
    <div className="space-y-6">
      <ResultHeader score={scoreNorm} level={level} />
      <DetectiveSquad detectives={detectives} metadata={metadata} />
      <AIExplanation summary={derived.aiSummary} details={derived.aiDetails} />
      <ExportButton data={results} />
      {derived.suspiciousTx.length > 0 && <SuspiciousTxList transactions={derived.suspiciousTx} />}
      {derived.connections.length > 0 && <SuspiciousConnections connections={derived.connections} />}
      {derived.timeline.length > 0 && <TimelineEvents events={derived.timeline} />}
      <NetworkGraph data={results.networkGraph} />
    </div>
  );
}
