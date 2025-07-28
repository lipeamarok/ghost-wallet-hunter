"""
AI Service

Handles AI-powered explanations and natural language generation for analysis results.
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from config.settings import settings
from schemas.analysis import WalletCluster

logger = logging.getLogger(__name__)


class AIService:
    """Service for AI-powered explanations and analysis."""

    def __init__(self):
        self.openai_available = bool(settings.OPENAI_API_KEY)
        if not self.openai_available:
            logger.warning("OpenAI API key not configured")

    async def generate_explanation(
        self,
        analysis_result,
        wallet_address: str
    ) -> str:
        """Generate a human-readable explanation of the analysis results."""
        try:
            if not settings.OPENAI_API_KEY:
                return self._generate_fallback_explanation(analysis_result, wallet_address)

            # Prepare context for AI
            context = self._prepare_analysis_context(analysis_result, wallet_address)

            # Generate explanation using OpenAI
            explanation = await self._call_openai_api(context)

            return explanation or self._generate_fallback_explanation(analysis_result, wallet_address)

        except Exception as e:
            logger.error(f"Failed to generate AI explanation: {e}")
            return self._generate_fallback_explanation(analysis_result, wallet_address)

    def _prepare_analysis_context(self, analysis_result, wallet_address: str) -> str:
        """Prepare context information for AI explanation."""

        # Basic analysis info
        risk_level = analysis_result.risk_level.value
        risk_score = analysis_result.risk_score
        cluster_count = len(analysis_result.clusters)
        total_connections = analysis_result.total_connections

        # Top clusters info
        top_clusters = sorted(analysis_result.clusters, key=lambda x: x.risk_score, reverse=True)[:3]

        # Detected patterns
        all_patterns = []
        for cluster in analysis_result.clusters:
            all_patterns.extend(cluster.patterns)
        unique_patterns = list(set(all_patterns))

        context = f"""
        Wallet Analysis Results for {wallet_address}:

        Overall Risk Assessment:
        - Risk Level: {risk_level.upper()}
        - Risk Score: {risk_score:.2f}/1.0
        - Total Clusters Found: {cluster_count}
        - Total Connections: {total_connections}

        Top Suspicious Clusters:
        """

        for i, cluster in enumerate(top_clusters, 1):
            context += f"""
        {i}. Wallet: {cluster.wallet_address[:8]}...{cluster.wallet_address[-8:]}
           - Risk Score: {cluster.risk_score:.2f}
           - Connections: {cluster.connections}
           - Volume: {cluster.total_volume_sol:.2f} SOL
           - Patterns: {', '.join(cluster.patterns) if cluster.patterns else 'None detected'}
        """

        if unique_patterns:
            context += f"\nDetected Suspicious Patterns: {', '.join(unique_patterns)}"

        return context

    async def _call_openai_api(self, context: str) -> Optional[str]:
        """Call OpenAI API to generate explanation."""
        try:
            if not self.openai_available:
                return None

            # Dynamic import to handle missing openai package gracefully
            try:
                from openai import AsyncOpenAI
            except ImportError:
                logger.warning("OpenAI package not installed")
                return None

            # Initialize client with error handling
            client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

            # Prepare the prompt
            system_prompt = """
            You are a blockchain security expert explaining wallet analysis results in simple, educational terms.

            Guidelines:
            - Use clear, non-technical language
            - Be educational and empathetic, not accusatory
            - Explain what the patterns might indicate
            - Emphasize this is probabilistic analysis, not definitive proof
            - Keep explanations concise (2-3 paragraphs maximum)
            - Focus on helping users understand blockchain security
            - Avoid making direct accusations of wrongdoing
            """

            user_prompt = f"""
            Please explain these blockchain wallet analysis results in simple terms:

            {context}

            Help the user understand:
            1. What these patterns might indicate
            2. Why this risk level was assigned
            3. What they should consider when interpreting these results

            Remember: This is educational analysis, not proof of wrongdoing.
            """

            # Make API call
            response = await client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=300,
                temperature=0.7
            )

            if response.choices and response.choices[0].message.content:
                return response.choices[0].message.content.strip()

            return None

        except Exception as e:
            logger.error(f"OpenAI API call failed: {e}")
            return None

    def _generate_fallback_explanation(self, analysis_result, wallet_address: str) -> str:
        """Generate a fallback explanation when AI is not available."""

        risk_level = analysis_result.risk_level.value
        cluster_count = len(analysis_result.clusters)

        # Collect patterns
        all_patterns = []
        for cluster in analysis_result.clusters:
            all_patterns.extend(cluster.patterns)
        unique_patterns = list(set(all_patterns))

        if risk_level == "low":
            explanation = f"Analysis of wallet {wallet_address[:8]}...{wallet_address[-8:]} shows a LOW risk profile. "
            explanation += f"Found {cluster_count} connected wallets with normal transaction patterns. "
            explanation += "No significant suspicious activity was detected."

        elif risk_level == "medium":
            explanation = f"Analysis of wallet {wallet_address[:8]}...{wallet_address[-8:]} shows a MEDIUM risk profile. "
            explanation += f"Found {cluster_count} connected wallets with some patterns that warrant attention. "

            if unique_patterns:
                explanation += f"Detected patterns include: {', '.join(unique_patterns)}. "

            explanation += "These patterns may indicate coordinated activity, but could also have legitimate explanations. "
            explanation += "Consider additional verification if this wallet is involved in significant transactions."

        else:  # high risk
            explanation = f"Analysis of wallet {wallet_address[:8]}...{wallet_address[-8:]} shows a HIGH risk profile. "
            explanation += f"Found {cluster_count} connected wallets with multiple suspicious patterns. "

            if unique_patterns:
                explanation += f"Detected patterns include: {', '.join(unique_patterns)}. "

            explanation += "These patterns suggest possible coordinated or automated activity. "
            explanation += "Exercise additional caution and consider further investigation before engaging with this wallet."

        explanation += "\n\nNote: This analysis is based on public blockchain data and uses probabilistic methods. "
        explanation += "Results should be used as guidance, not definitive proof of suspicious activity."

        return explanation

    async def generate_pattern_explanation(self, pattern: str) -> str:
        """Generate explanation for a specific pattern."""

        pattern_explanations = {
            "simultaneous_transactions":
                "Multiple transactions occurring at the same time across different wallets, "
                "which might indicate coordinated activity or automated systems.",

            "high_frequency_transfers":
                "Rapid succession of transfers within a short time period, "
                "which could suggest automated trading or money movement patterns.",

            "identical_amounts":
                "Multiple transactions with exactly the same amounts, "
                "which might indicate programmatic or coordinated transfers.",

            "round_amounts":
                "Transactions predominantly using round numbers (1, 5, 10 SOL etc.), "
                "which could suggest manual or simplified automated transactions.",

            "multiple_connections":
                "Wallet connected to many other wallets, "
                "which might indicate high activity or potential clustering behavior."
        }

        return pattern_explanations.get(
            pattern,
            f"Pattern '{pattern}' detected in transaction analysis."
        )
