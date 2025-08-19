/**
 * Ghost Wallet Hunter - Data Mappers
 * ==================================
 *
 * Transforma a resposta real do backend Julia em formato compatível com frontend.
 * Mapeia dados dos 7 agentes detective para estrutura esperada pela UI.
 */

/**
 * Calculate risk level from numerical score
 */
const calculateRiskLevel = (score) => {
  if (score >= 80) return 'High';
  if (score >= 50) return 'Medium';
  if (score >= 20) return 'Low';
  return 'Very Low';
};

/**
 * Mapeia dados de um agente individual - Compatível com Julia revolutionary structure
 */
export const mapAgentData = (agentId, agentData) => {
  if (!agentData) return null;

  // Julia returns data directly, not nested in analysis_results
  const analysis = agentData.analysis || agentData;
  const status = agentData.status || 'unknown';

  // Extract key information from Julia response structure
  const riskScore = (agentData.risk_score || 0) * 100; // Convert 0.0-1.0 to 0-100
  const riskLevel = agentData.analysis?.risk_level || 'LOW';
  const confidence = (agentData.confidence || 0.7) * 100; // Convert to percentage
  const conclusion = agentData.conclusion || agentData.verdict || '';
  const totalTransactions = agentData.analysis?.total_transactions || 0;

  // Map detective info based on agent ID
  const detectiveInfo = {
    poirot: { name: 'Hercule Poirot', specialty: 'methodical_analysis' },
    marple: { name: 'Miss Marple', specialty: 'pattern_observation' },
    spade: { name: 'Sam Spade', specialty: 'noir_investigation' },
    marlowe: { name: 'Philip Marlowe', specialty: 'deep_analysis' },
    dupin: { name: 'Auguste Dupin', specialty: 'analytical_reasoning' },
    shadow: { name: 'The Shadow', specialty: 'stealth_investigation' },
    raven: { name: 'Detective Raven', specialty: 'dark_investigation' }
  };

  const detective = detectiveInfo[agentId]?.name || `Detective ${agentId}`;
  const methodology = detectiveInfo[agentId]?.specialty || 'general_investigation';

  return {
    detective,
    methodology,
    riskScore,
    confidence,
    conclusion,
    riskLevel,
    totalTransactions,
    analysis: analysis,
    timestamp: agentData.timestamp || new Date().toISOString(),

    // Status helpers - Julia returns "completed" for success, other status for failures
    isCompleted: status === 'completed',
    isFailed: status !== 'completed',
    status,

    // Additional data
    investigationId: agentData.investigating_agent || agentId,
    realBlockchainData: analysis.blockchain_confirmed || true,
    patterns: analysis.patterns_detected || [],
    riskFactors: analysis.risk_factors || [],
    blacklistStatus: analysis.blacklist_status || false
  };
};

/**
 * Mapeia resposta completa do Julia backend - Compatível com comprehensive investigation
 */
export const mapJuliaResponse = (rawResponse) => {
  if (!rawResponse) return null;

  // Handle comprehensive investigation response from Julia
  if (rawResponse.individual_results && rawResponse.successful_investigations !== undefined) {
    // Comprehensive investigation format
    const detectives = {};

    // Map each detective agent's results
    for (const [agentId, agentData] of Object.entries(rawResponse.individual_results)) {
      detectives[agentId] = mapAgentData(agentId, agentData);
    }

    // Calculate totals
    const totalAgents = rawResponse.participating_detectives?.length || Object.keys(rawResponse.individual_results).length;
    const successfulAgents = rawResponse.successful_investigations || 0;
    const failedAgents = rawResponse.failed_investigations || 0;

    return {
      // Identification
      id: rawResponse.investigation_id,
      investigationId: rawResponse.investigation_id,

      // Summary from consensus
      summary: {
        riskScore: (rawResponse.consensus_risk_score || 0) * 100, // Convert 0.0-1.0 to 0-100
        confidence: Math.round((successfulAgents / totalAgents) * 100) || 70,
        riskLevel: calculateRiskLevel((rawResponse.consensus_risk_score || 0) * 100),
        successfulAgents,
        failedAgents,
        totalAgents,
        agentSuccessRate: totalAgents > 0 ?
          ((successfulAgents / totalAgents) * 100).toFixed(1) : '0',
        flaggedActivities: [], // Will be aggregated from agents
        recommendations: []
      },

      // Individual detectives
      detectives,

      // Metadata
      metadata: {
        walletAddress: rawResponse.wallet_address,
        completionTime: rawResponse.timestamp,
        duration: 0, // Julia investigations are fast
        servicesUsed: { julia: true },
        totalAgents,
        completedAgents: successfulAgents,
        investigationId: rawResponse.investigation_id,
        frameworkStatus: rawResponse.framework_status
      },

      // Raw results for advanced analysis
      rawResults: rawResponse
    };
  }

  // Handle single agent response (legacy compatibility)
  if (rawResponse.investigating_agent && rawResponse.analysis_results) {
    const agentId = rawResponse.investigating_agent;
    const detective = mapAgentData(agentId, rawResponse);

    return {
      id: `single-${agentId}-${Date.now()}`,
      investigationId: `single-${agentId}-${Date.now()}`,

      summary: {
        riskScore: detective.riskScore || 0,
        confidence: detective.confidence || 70,
        riskLevel: detective.riskLevel || 'UNKNOWN',
        successfulAgents: detective.isCompleted ? 1 : 0,
        failedAgents: detective.isFailed ? 1 : 0,
        totalAgents: 1,
        agentSuccessRate: detective.isCompleted ? '100.0' : '0.0',
        flaggedActivities: detective.riskFactors || [],
        recommendations: []
      },

      detectives: {
        [agentId]: detective
      },

      metadata: {
        walletAddress: rawResponse.wallet_address,
        completionTime: rawResponse.timestamp,
        duration: 0,
        servicesUsed: { julia: true },
        totalAgents: 1,
        completedAgents: detective.isCompleted ? 1 : 0
      },

      rawResults: rawResponse
    };
  }

  // Fallback for legacy format (from old implementation)
  const {
    success,
    investigation_id,
    shortId,
    status,
    wallet_address,
    investigation_type,
    timestamp,
    timing,
    results,
    metrics,
    version
  } = rawResponse;

  const { normalized, raw } = results || {};
  const { summary = {}, detailedFindings = {}, metadata = {} } = normalized || {};

  // Mapear todos os 7 agentes
  const detectives = {};
  if (detailedFindings) {
    Object.entries(detailedFindings).forEach(([agentId, agentData]) => {
      detectives[agentId] = mapAgentData(agentId, agentData);
    });
  }

  // Calcular estatísticas dos agentes
  const agentStats = Object.values(detectives).filter(Boolean);
  const completedAgents = agentStats.filter(agent => agent && agent.isCompleted).length;
  const failedAgents = agentStats.filter(agent => agent && agent.isFailed).length;
  const totalAgents = agentStats.length;

  return {
    // Identificação
    id: investigation_id,
    shortId,
    investigationId: investigation_id,

    // Status geral
    success,
    status,
    walletAddress: wallet_address,
    investigationType: investigation_type,
    timestamp,
    timing,
    version,

    // Summary consolidado
    summary: {
      riskScore: summary.riskScore || 0,
      riskScoreRaw: summary.riskScoreRaw || 0,
      confidence: summary.confidence || 0,
      confidenceNormalized: summary.confidenceNormalized || 0,
      riskLevel: summary.riskScore >= 50 ? 'High' : summary.riskScore >= 20 ? 'Medium' : 'Low',
      confidenceLevel: summary.confidence >= 90 ? 'Very High' :
                      summary.confidence >= 70 ? 'High' :
                      summary.confidence >= 50 ? 'Medium' : 'Low',

      // Status dos agentes
      successfulAgents: completedAgents,
      failedAgents,
      totalAgents,
      agentSuccessRate: totalAgents > 0 ? (completedAgents / totalAgents * 100).toFixed(1) : '0',

      // Dados adicionais
      failureReason: summary.failureReason,
      analysisAvailable: summary.analysisAvailable !== false,
      recommendations: summary.recommendations || [],
      flaggedActivities: summary.flaggedActivities || [],
      degraded: summary.degraded || false,
      degradedAgents: summary.degradedAgents || false
    },

    // Agentes individuais
    detectives,

    // Dados brutos para análise avançada
    rawResults: raw,

    // Metadata
    metadata: {
      duration: timing?.duration_ms || 0,
      durationFormatted: formatDuration(timing?.duration_ms || 0),
      completionTime: timing?.completed_at || timestamp,
      startedAt: timing?.started_at,
      agents: metadata.agents || Object.keys(detailedFindings),
      servicesUsed: metadata.servicesUsed || { julia: true },
      version: metadata.version || version
    },

    // Métricas finais
    metrics: {
      riskScore: metrics?.riskScore || summary.riskScore || 0,
      confidence: metrics?.confidence || summary.confidence || 0
    }
  };
};

/**
 * Formata duração em ms para formato legível
 */
export const formatDuration = (durationMs) => {
  if (!durationMs || durationMs <= 0) return '0s';

  const seconds = Math.floor(durationMs / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);

  if (hours > 0) {
    return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds % 60}s`;
  } else {
    return `${seconds}s`;
  }
};

/**
 * Mapeia dados para componente de timeline
 */
export const mapTimelineData = (detectives) => {
  const events = [];

  Object.entries(detectives).forEach(([key, detective]) => {
    if (!detective) return;

    events.push({
      id: `${key}-start`,
      detective: detective.detective,
      methodology: detective.methodology,
      timestamp: detective.timestamp,
      type: detective.isCompleted ? 'success' : 'failure',
      status: detective.status,
      conclusion: detective.conclusion,
      riskScore: detective.riskScore,
      confidence: detective.confidence
    });
  });

  // Ordenar por timestamp
  return events.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
};

/**
 * Mapeia dados para gráfico de rede (se disponível)
 */
export const mapNetworkData = (detectives) => {
  const nodes = [];
  const edges = [];

  // Adicionar nó central (wallet)
  nodes.push({
    id: 'wallet',
    label: 'Target Wallet',
    type: 'wallet',
    group: 'center'
  });

  // Adicionar nós dos agentes
  Object.entries(detectives).forEach(([key, detective]) => {
    if (!detective) return;

    nodes.push({
      id: key,
      label: detective.detective,
      type: 'detective',
      group: detective.isCompleted ? 'success' : 'failure',
      riskScore: detective.riskScore,
      confidence: detective.confidence,
      methodology: detective.methodology
    });

    // Conectar ao wallet central
    edges.push({
      from: 'wallet',
      to: key,
      weight: detective.confidence / 100,
      color: detective.isCompleted ? '#10B981' : '#EF4444'
    });
  });

  return { nodes, edges };
};

export default {
  mapJuliaResponse,
  mapAgentData,
  mapTimelineData,
  mapNetworkData,
  formatDuration
};
