"""
Analysis Service

Core business logic for wallet cluster analysis and risk assessment.
Enhanced with JuliaOS AI-powered analysis capabilities.
"""

import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Set, Tuple, Optional
from collections import defaultdict, deque
import statistics

from services.solana_service import SolanaService
from services.juliaos_service import get_juliaos_service, JuliaOSService
from schemas.analysis import WalletCluster, AnalysisMetadata, RiskLevel
from config.settings import settings

logger = logging.getLogger(__name__)


class AnalysisResult:
    """Container for analysis results."""

    def __init__(self):
        self.clusters: List[WalletCluster] = []
        self.risk_score: float = 0.0
        self.risk_level: RiskLevel = RiskLevel.LOW
        self.total_connections: int = 0
        self.metadata: Optional[AnalysisMetadata] = None


class AnalysisService:
    """Service for performing wallet cluster analysis."""

    def __init__(self):
        self.solana_service = None

    async def analyze_wallet(
        self,
        wallet_address: str,
        depth: int = 2
    ) -> AnalysisResult:
        """Perform comprehensive wallet analysis enhanced with JuliaOS AI."""
        start_time = datetime.now(timezone.utc)

        try:
            logger.info(f"Starting AI-enhanced analysis for {wallet_address} with depth {depth}")

            # Initialize services
            self.solana_service = SolanaService()
            juliaos_service = get_juliaos_service()

            # Get wallet transactions
            transactions = await self._get_wallet_transactions(wallet_address)

            # Build transaction graph
            graph = await self._build_transaction_graph(wallet_address, transactions, depth)

            # Detect clusters
            clusters = await self._detect_clusters(graph, wallet_address)

            # Calculate risk scores
            risk_analysis = await self._calculate_risk_scores(clusters, transactions)

            # Enhanced JuliaOS AI Analysis
            ai_analysis = await self._perform_juliaos_analysis(
                wallet_address,
                transactions,
                clusters,
                juliaos_service
            )

            # Combine traditional and AI analysis
            combined_risk_score = self._combine_risk_scores(
                risk_analysis['overall_risk'],
                ai_analysis.get('risk_score', 0)
            )

            # Prepare result
            result = AnalysisResult()
            result.clusters = clusters
            result.risk_score = combined_risk_score
            result.risk_level = self._determine_risk_level(combined_risk_score)
            result.total_connections = len(graph.get(wallet_address, {}))

            # Enhanced metadata with AI insights
            end_time = datetime.now(timezone.utc)
            result.metadata = AnalysisMetadata(
                analysis_duration_ms=(end_time - start_time).total_seconds() * 1000,
                transactions_analyzed=len(transactions),
                wallets_scanned=len(graph),
                depth_reached=depth,
                patterns_detected=risk_analysis.get('patterns', []) + ai_analysis.get('suspicious_patterns', []),
                ai_insights=ai_analysis.get('ai_insights', 'JuliaOS analysis unavailable'),
                analysis_method=ai_analysis.get('analysis_method', 'traditional+ai')
            )

            logger.info(f"AI-enhanced analysis completed for {wallet_address}")
            return result

        except Exception as e:
            logger.error(f"Analysis failed for {wallet_address}: {e}", exc_info=True)
            raise

    async def quick_analyze_wallet(self, wallet_address: str) -> AnalysisResult:
        """Perform a quick analysis with limited depth."""
        return await self.analyze_wallet(wallet_address, depth=1)

    async def _get_wallet_transactions(self, wallet_address: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent transactions for a wallet."""
        try:
            if not self.solana_service:
                raise RuntimeError("Solana service not initialized")

            transactions = await self.solana_service.get_wallet_transactions(
                wallet_address,
                limit=limit
            )

            # Filter successful transactions only
            successful_txs = [tx for tx in transactions if tx.get('success', True)]

            logger.debug(f"Retrieved {len(successful_txs)} transactions for {wallet_address}")
            return successful_txs

        except Exception as e:
            logger.error(f"Failed to get transactions for {wallet_address}: {e}")
            return []

    async def _build_transaction_graph(
        self,
        start_wallet: str,
        transactions: List[Dict[str, Any]],
        max_depth: int
    ) -> Dict[str, Dict[str, List[Dict[str, Any]]]]:
        """Build a graph of wallet connections from transactions."""
        graph = defaultdict(lambda: defaultdict(list))
        visited = set()
        queue = deque([(start_wallet, 0)])  # (wallet, depth)

        while queue and len(visited) < settings.MAX_CLUSTER_SIZE:
            current_wallet, depth = queue.popleft()

            if current_wallet in visited or depth >= max_depth:
                continue

            visited.add(current_wallet)

            # Get transactions for current wallet
            if depth > 0:  # Don't re-fetch for start wallet
                wallet_transactions = await self._get_wallet_transactions(current_wallet, limit=50)
            else:
                wallet_transactions = transactions

            # Process each transaction
            for tx in wallet_transactions:
                from_addr = tx.get('from_address')
                to_addr = tx.get('to_address')

                # Add connections to graph
                if from_addr and to_addr:
                    if from_addr == current_wallet:
                        graph[from_addr][to_addr].append(tx)
                        if depth < max_depth - 1:
                            queue.append((to_addr, depth + 1))
                    elif to_addr == current_wallet:
                        graph[to_addr][from_addr].append(tx)
                        if depth < max_depth - 1:
                            queue.append((from_addr, depth + 1))

        logger.debug(f"Built graph with {len(graph)} wallets")
        return dict(graph)

    async def _detect_clusters(
        self,
        graph: Dict[str, Dict[str, List[Dict[str, Any]]]],
        start_wallet: str
    ) -> List[WalletCluster]:
        """Detect suspicious wallet clusters."""
        clusters = []

        for wallet, connections in graph.items():
            if wallet == start_wallet:
                continue

            cluster_info = await self._analyze_wallet_cluster(wallet, connections, graph)

            if cluster_info and len(connections) >= settings.MIN_CONNECTIONS_FOR_CLUSTER:
                clusters.append(cluster_info)

        # Sort by risk score
        clusters.sort(key=lambda x: x.risk_score, reverse=True)

        return clusters[:settings.MAX_CLUSTER_SIZE]

    async def _analyze_wallet_cluster(
        self,
        wallet: str,
        connections: Dict[str, List[Dict[str, Any]]],
        full_graph: Dict[str, Dict[str, List[Dict[str, Any]]]]
    ) -> WalletCluster:
        """Analyze a specific wallet cluster for suspicious patterns."""

        all_transactions = []
        for tx_list in connections.values():
            all_transactions.extend(tx_list)

        if not all_transactions:
            # Return a default cluster with minimal data
            return WalletCluster(
                wallet_address=wallet,
                risk_score=0.0,
                risk_level=RiskLevel.LOW,
                connections=0,
                total_volume_sol=0.0,
                last_activity=None,
                patterns=[]
            )

        # Calculate metrics
        total_volume = sum(tx.get('amount_sol', 0) for tx in all_transactions)
        connection_count = len(connections)

        # Detect patterns
        patterns = await self._detect_patterns(wallet, all_transactions, connections)

        # Calculate risk score
        risk_score = await self._calculate_wallet_risk_score(
            wallet, all_transactions, patterns, connection_count
        )

        # Get last activity
        timestamps = [tx.get('timestamp') for tx in all_transactions if tx.get('timestamp')]
        last_activity = max(timestamps) if timestamps else None

        return WalletCluster(
            wallet_address=wallet,
            risk_score=risk_score,
            risk_level=self._determine_risk_level(risk_score),
            connections=connection_count,
            total_volume_sol=total_volume,
            last_activity=last_activity,
            patterns=patterns
        )

    async def _detect_patterns(
        self,
        wallet: str,
        transactions: List[Dict[str, Any]],
        connections: Dict[str, List[Dict[str, Any]]]
    ) -> List[str]:
        """Detect suspicious patterns in wallet behavior."""
        patterns = []

        if not transactions:
            return patterns

        # Pattern 1: Simultaneous transactions
        if await self._detect_simultaneous_transactions(transactions):
            patterns.append("simultaneous_transactions")

        # Pattern 2: High frequency transfers
        if await self._detect_high_frequency_transfers(transactions):
            patterns.append("high_frequency_transfers")

        # Pattern 3: Identical amounts
        if await self._detect_identical_amounts(transactions):
            patterns.append("identical_amounts")

        # Pattern 4: Round number amounts
        if await self._detect_round_amounts(transactions):
            patterns.append("round_amounts")

        # Pattern 5: Multiple connections
        if len(connections) > 10:
            patterns.append("multiple_connections")

        return patterns

    async def _detect_simultaneous_transactions(self, transactions: List[Dict[str, Any]]) -> bool:
        """Detect if multiple transactions happened simultaneously."""
        if len(transactions) < 3:
            return False

        # Group transactions by time windows (5 minute intervals)
        time_groups = defaultdict(list)
        for tx in transactions:
            if tx.get('timestamp'):
                # Round timestamp to 5-minute intervals
                rounded_time = tx['timestamp'].replace(second=0, microsecond=0)
                minute = rounded_time.minute
                rounded_minute = (minute // 5) * 5
                rounded_time = rounded_time.replace(minute=rounded_minute)
                time_groups[rounded_time].append(tx)

        # Check if any time window has 3+ transactions
        return any(len(txs) >= 3 for txs in time_groups.values())

    async def _detect_high_frequency_transfers(self, transactions: List[Dict[str, Any]]) -> bool:
        """Detect high frequency transfers."""
        if len(transactions) < 5:
            return False

        # Sort by timestamp
        sorted_txs = sorted(
            [tx for tx in transactions if tx.get('timestamp')],
            key=lambda x: x['timestamp']
        )

        if len(sorted_txs) < 5:
            return False

        # Check for 5+ transactions within 1 hour
        for i in range(len(sorted_txs) - 4):
            time_diff = sorted_txs[i + 4]['timestamp'] - sorted_txs[i]['timestamp']
            if time_diff.total_seconds() <= 3600:  # 1 hour
                return True

        return False

    async def _detect_identical_amounts(self, transactions: List[Dict[str, Any]]) -> bool:
        """Detect transactions with identical amounts."""
        amounts = [tx.get('amount_sol', 0) for tx in transactions]
        amount_counts = defaultdict(int)

        for amount in amounts:
            if amount > 0:
                amount_counts[amount] += 1

        # Check if any amount appears 3+ times
        return any(count >= 3 for count in amount_counts.values())

    async def _detect_round_amounts(self, transactions: List[Dict[str, Any]]) -> bool:
        """Detect round number amounts (possible automation)."""
        round_amounts = 0
        total_amounts = 0

        for tx in transactions:
            amount = tx.get('amount_sol', 0)
            if amount > 0:
                total_amounts += 1
                # Check if amount is a round number
                if amount == int(amount) or amount in [0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0]:
                    round_amounts += 1

        # If 70%+ of amounts are round numbers
        return total_amounts > 0 and (round_amounts / total_amounts) >= 0.7

    async def _calculate_wallet_risk_score(
        self,
        wallet: str,
        transactions: List[Dict[str, Any]],
        patterns: List[str],
        connection_count: int
    ) -> float:
        """Calculate risk score for a specific wallet."""
        base_score = 0.0

        # Pattern-based scoring
        pattern_weights = {
            "simultaneous_transactions": 0.3,
            "high_frequency_transfers": 0.4,
            "identical_amounts": 0.2,
            "round_amounts": 0.1,
            "multiple_connections": 0.2
        }

        for pattern in patterns:
            base_score += pattern_weights.get(pattern, 0.1)

        # Connection count factor
        if connection_count > 20:
            base_score += 0.2
        elif connection_count > 10:
            base_score += 0.1

        # Volume factor (very high volumes might be suspicious)
        total_volume = sum(tx.get('amount_sol', 0) for tx in transactions)
        if total_volume > 1000:  # More than 1000 SOL
            base_score += 0.1

        return min(base_score, 1.0)  # Cap at 1.0

    async def _calculate_risk_scores(
        self,
        clusters: List[WalletCluster],
        transactions: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Calculate overall risk assessment."""
        if not clusters:
            return {
                'overall_risk': 0.0,
                'patterns': []
            }

        # Calculate weighted average risk score
        total_risk = sum(cluster.risk_score * cluster.connections for cluster in clusters)
        total_connections = sum(cluster.connections for cluster in clusters)

        overall_risk = total_risk / total_connections if total_connections > 0 else 0.0

        # Collect all detected patterns
        all_patterns = []
        for cluster in clusters:
            all_patterns.extend(cluster.patterns)

        unique_patterns = list(set(all_patterns))

        return {
            'overall_risk': min(overall_risk, 1.0),
            'patterns': unique_patterns
        }

    def _determine_risk_level(self, risk_score: float) -> RiskLevel:
        """Determine risk level from risk score."""
        if risk_score < 0.3:
            return RiskLevel.LOW
        elif risk_score < 0.7:
            return RiskLevel.MEDIUM
        else:
            return RiskLevel.HIGH

    async def _perform_juliaos_analysis(
        self,
        wallet_address: str,
        transactions: List[Dict[str, Any]],
        clusters: List[WalletCluster],
        juliaos_client
    ) -> Dict[str, Any]:
        """
        Perform AI-enhanced analysis using JuliaOS with real detective agents.

        Args:
            wallet_address: Target wallet address
            transactions: Wallet transactions
            clusters: Detected clusters
            juliaos_client: JuliaOS client instance

        Returns:
            AI analysis results
        """
        try:
            # 1. Check if JuliaOS agents are available
            agents = await juliaos_client.list_agents()
            ghost_agents = [a for a in agents if a.id.startswith("ghost_")]

            if not ghost_agents:
                logger.warning("No Ghost Wallet Hunter agents found in JuliaOS - using fallback")
                return self._fallback_analysis()

            logger.info(f"🕵️ Found {len(ghost_agents)} JuliaOS detective agents available")

            # 2. Prepare investigation payload for detective_investigation strategy
            investigation_payload = {
                "wallet_address": wallet_address,
                "transactions": transactions[:50],  # Limit for performance
                "clusters": [
                    {
                        "wallet_address": cluster.wallet_address,
                        "connections": cluster.connections,
                        "patterns": cluster.patterns,
                        "risk_score": cluster.risk_score,
                        "total_volume_sol": cluster.total_volume_sol
                    }
                    for cluster in clusters
                ],
                "analysis_depth": "comprehensive",
                "investigation_type": "suspicious_wallet_clustering",
                "network": "solana",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }

            # 3. Use primary detective agent as coordinator (typically Poirot)
            primary_agent = ghost_agents[0]  # Use first available agent as coordinator
            logger.info(f"🎯 Using {primary_agent.name} as primary detective coordinator")

            # 4. Trigger detective investigation via webhook
            webhook_success = await juliaos_client.trigger_agent_webhook(
                agent_id=primary_agent.id,
                payload=investigation_payload
            )

            if not webhook_success:
                logger.warning("JuliaOS webhook trigger failed - using fallback")
                return self._fallback_analysis()

            # 5. Wait a moment for processing and get analysis output
            await asyncio.sleep(2)  # Give JuliaOS time to process

            analysis_output = await juliaos_client.get_agent_output(primary_agent.id)

            if analysis_output:
                logger.info("✅ JuliaOS detective analysis completed successfully")
                return self._parse_juliaos_output(analysis_output)
            else:
                logger.warning("No output received from JuliaOS analysis")
                return self._fallback_analysis()

        except Exception as e:
            logger.error(f"JuliaOS analysis failed: {e}")
            return self._fallback_analysis()

    def _parse_juliaos_output(self, juliaos_output: Dict[str, Any]) -> Dict[str, Any]:
        """Parse JuliaOS detective analysis output into expected format"""
        try:
            # Extract meaningful data from JuliaOS output
            risk_score = juliaos_output.get("risk_score", 0)
            risk_level = juliaos_output.get("risk_level", "unknown")
            insights = juliaos_output.get("analysis", "JuliaOS analysis completed")
            patterns = juliaos_output.get("suspicious_patterns", [])

            return {
                "risk_score": risk_score,
                "risk_level": risk_level,
                "suspicious_patterns": patterns,
                "ai_insights": insights,
                "analysis_method": "juliaos_detective_investigation"
            }

        except Exception as e:
            logger.error(f"Error parsing JuliaOS output: {e}")
            return self._fallback_analysis()

    def _fallback_analysis(self) -> Dict[str, Any]:
        """Fallback analysis when JuliaOS is unavailable"""
        return {
            "risk_score": 0,
            "risk_level": "unknown",
            "suspicious_patterns": [],
            "ai_insights": "JuliaOS analysis unavailable - using traditional analysis only",
            "analysis_method": "traditional_fallback"
        }

    def _combine_risk_scores(self, traditional_score: float, ai_score: float) -> float:
        """
        Combine traditional analysis score with AI analysis score.

        Args:
            traditional_score: Score from traditional pattern analysis
            ai_score: Score from JuliaOS AI analysis (0-100)

        Returns:
            Combined risk score (0-1)
        """
        # Normalize AI score to 0-1 range
        normalized_ai_score = min(ai_score / 100.0, 1.0) if ai_score > 0 else 0.0

        # Weighted combination: 60% traditional + 40% AI
        # This gives preference to proven traditional methods while incorporating AI insights
        combined_score = (0.6 * traditional_score) + (0.4 * normalized_ai_score)

        # Apply boost if both methods agree on high risk
        if traditional_score > 0.7 and normalized_ai_score > 0.7:
            combined_score = min(combined_score * 1.1, 1.0)  # 10% boost, capped at 1.0

        return min(combined_score, 1.0)
