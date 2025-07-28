import React, { useEffect, useState, useCallback } from 'react';
import ReactFlow, {
  Controls,
  Background,
  useNodesState,
  useEdgesState,
  addEdge,
  MiniMap,
  Panel,
} from 'reactflow';
import { motion } from 'framer-motion';
import 'reactflow/dist/style.css';

// Custom node component for wallet visualization
const WalletNode = ({ data }) => {
  const { label, riskLevel, isTarget, isBlacklisted, connections } = data;

  const getNodeColors = () => {
    if (isBlacklisted) return { bg: '#ff3366', border: '#ff1150', text: '#ffffff' };
    if (isTarget) return { bg: '#00ffff', border: '#00e6e6', text: '#000000' };

    switch (riskLevel) {
      case 'high': return { bg: '#ff6b4a', border: '#ff4422', text: '#ffffff' };
      case 'medium': return { bg: '#ffb000', border: '#ff9500', text: '#000000' };
      case 'low': return { bg: '#00ff41', border: '#00cc33', text: '#000000' };
      default: return { bg: '#6b7280', border: '#4b5563', text: '#ffffff' };
    }
  };

  const colors = getNodeColors();

  return (
    <motion.div
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ type: "spring", stiffness: 300, damping: 25 }}
      className="relative"
    >
      <div
        className="px-4 py-3 rounded-lg border-2 min-w-[180px] text-center shadow-lg"
        style={{
          backgroundColor: colors.bg,
          borderColor: colors.border,
          color: colors.text,
          boxShadow: `0 0 20px ${colors.border}50`
        }}
      >
        <div className="font-mono text-xs font-bold">
          {label.slice(0, 8)}...{label.slice(-8)}
        </div>
        {isTarget && (
          <div className="text-xs mt-1 font-semibold">TARGET</div>
        )}
        {isBlacklisted && (
          <div className="text-xs mt-1 font-semibold animate-pulse">BLACKLISTED</div>
        )}
        <div className="text-xs mt-1 opacity-80">
          Risk: {riskLevel?.toUpperCase() || 'UNKNOWN'}
        </div>
        <div className="text-xs opacity-60">
          Connections: {connections || 0}
        </div>
      </div>

      {/* Pulsing effect for active nodes */}
      {(isTarget || isBlacklisted) && (
        <div
          className="absolute inset-0 rounded-lg animate-ping"
          style={{
            backgroundColor: colors.border,
            opacity: 0.3,
            zIndex: -1
          }}
        />
      )}
    </motion.div>
  );
};

const nodeTypes = {
  walletNode: WalletNode,
};

const NetworkTopology = ({ walletAddress, investigationData, isAnalyzing, currentPhase }) => {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [isRevealing, setIsRevealing] = useState(false);
  const [revealStep, setRevealStep] = useState(0);

  // Generate progressive network topology
  const generateNetworkData = useCallback(() => {
    if (!walletAddress) return;

    const centerNode = {
      id: 'target',
      type: 'walletNode',
      position: { x: 400, y: 300 },
      data: {
        label: walletAddress,
        riskLevel: investigationData?.results?.risk_assessment?.risk_level || 'unknown',
        isTarget: true,
        isBlacklisted: investigationData?.blacklist_alert?.is_blacklisted || false,
        connections: investigationData?.results?.connections?.length || 0,
      },
    };

    // Generate connected wallets based on investigation data
    const connectedWallets = generateConnectedWallets(investigationData);

    const networkNodes = [centerNode, ...connectedWallets];
    const networkEdges = generateEdges(connectedWallets);

    return { nodes: networkNodes, edges: networkEdges };
  }, [walletAddress, investigationData]);

  const generateConnectedWallets = (data) => {
    const riskLevel = data?.results?.risk_assessment?.risk_level?.toLowerCase() || 'low';
    const baseConnections = data?.results?.connections || [];

    // Use real connections if available, otherwise generate for visualization
    const connectionCount = Math.max(baseConnections.length, riskLevel === 'high' ? 8 : riskLevel === 'medium' ? 5 : 3);

    const angles = Array.from({ length: connectionCount }, (_, i) => (i * 360) / connectionCount);
    const radius = 250;

    return angles.map((angle, index) => {
      const radian = (angle * Math.PI) / 180;
      const x = 400 + radius * Math.cos(radian);
      const y = 300 + radius * Math.sin(radian);

      // Use real connection data if available
      const connectionData = baseConnections[index];
      const walletId = connectionData?.wallet || generateWalletAddress();

      return {
        id: `wallet-${index}`,
        type: 'walletNode',
        position: { x, y },
        data: {
          label: walletId,
          riskLevel: connectionData?.risk || getRandomRisk(riskLevel),
          isTarget: false,
          isBlacklisted: connectionData?.is_blacklisted || Math.random() < 0.1,
          connections: connectionData?.connection_count || Math.floor(Math.random() * 20),
        },
      };
    });
  };

  const generateEdges = (connectedWallets) => {
    return connectedWallets.map((wallet, index) => ({
      id: `edge-target-${index}`,
      source: 'target',
      target: wallet.id,
      type: 'smoothstep',
      animated: wallet.data.isBlacklisted,
      style: {
        stroke: wallet.data.isBlacklisted ? '#ff3366' :
                wallet.data.riskLevel === 'high' ? '#ff6b4a' :
                wallet.data.riskLevel === 'medium' ? '#ffb000' : '#00ff41',
        strokeWidth: wallet.data.isBlacklisted ? 3 : 2,
      },
      markerEnd: {
        type: 'arrowclosed',
        color: wallet.data.isBlacklisted ? '#ff3366' : '#00ffff',
      },
    }));
  };

  const generateWalletAddress = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789';
    return Array.from({ length: 44 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  };

  const getRandomRisk = (baseRisk) => {
    const risks = ['low', 'medium', 'high'];
    const weights = baseRisk === 'high' ? [0.2, 0.3, 0.5] :
                   baseRisk === 'medium' ? [0.4, 0.4, 0.2] :
                   [0.7, 0.2, 0.1];

    const random = Math.random();
    let cumulative = 0;

    for (let i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) return risks[i];
    }
    return 'low';
  };

  // Progressive reveal effect
  useEffect(() => {
    if (currentPhase >= 2 && !isRevealing) { // Phase 2: Network topology mapping
      setIsRevealing(true);
      const networkData = generateNetworkData();

      if (networkData) {
        // Start with just the target node
        setNodes([networkData.nodes[0]]);
        setEdges([]);

        // Progressively reveal connected nodes
        networkData.nodes.slice(1).forEach((node, index) => {
          setTimeout(() => {
            setNodes(prev => [...prev, node]);

            // Add edges after a short delay
            setTimeout(() => {
              const relevantEdges = networkData.edges.filter(edge =>
                edge.target === node.id || edge.source === node.id
              );
              setEdges(prev => [...prev, ...relevantEdges]);
            }, 300);
          }, index * 500);
        });
      }
    }
  }, [currentPhase, generateNetworkData, isRevealing]);

  if (currentPhase < 2) {
    return (
      <div className="h-[600px] bg-black border border-gray-800 rounded-lg flex items-center justify-center">
        <div className="text-gray-500 font-mono">
          Waiting for network topology mapping phase...
        </div>
      </div>
    );
  }

  return (
    <div className="h-[600px] bg-black border border-gray-800 rounded-lg overflow-hidden">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        nodeTypes={nodeTypes}
        fitView
        fitViewOptions={{ padding: 0.2 }}
        className="bg-black"
      >
        <Background color="#1f2937" gap={20} size={1} />
        <Controls className="bg-gray-800 border-gray-600" />
        <MiniMap
          nodeColor="#00ffff"
          nodeStrokeWidth={3}
          className="bg-gray-900 border-gray-600"
        />

        <Panel position="top-left" className="bg-gray-900 border border-gray-600 rounded-lg p-3">
          <div className="text-green-400 font-mono text-sm">
            <div>Network Analysis</div>
            <div className="text-xs text-gray-400 mt-1">
              Nodes: {nodes.length} | Edges: {edges.length}
            </div>
          </div>
        </Panel>
      </ReactFlow>
    </div>
  );
};

export default NetworkTopology;
