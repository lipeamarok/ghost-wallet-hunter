"""
Ghost Wallet Hunter - Poirot (Transaction Analysis Agent)

Hercule Poirot - The master of method, meticulous in examining each transaction.
"Little grey cells" applied to blockchain analysis with surgical precision.
Enhanced with contextual token recog        logger.info(f"TARGET {self.name}: 'Mon ami, the deduction is complete! The truth emerges!'")ition and enriched analysis.
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

from services.juliaos_only_ai_service import get_juliaos_ai_service
from services.solana_service import SolanaService
from .shared_models import RiskLevel, WalletCluster, AnalysisResult

logger = logging.getLogger(__name__)


class PoirotAgent:
    """
     HERCULE POIROT - Transaction Analysis Detective

    The Belgian master of deduction applied to blockchain. Poirot examines each transaction
    with methodological precision, using his "little grey cells" to detect
    the smallest suspicious details in fund movement patterns.

    NOW ENHANCED with contextual token recognition:
    - Can identify specific tokens: "Ah, this is the Samoyed Coin (SAMO)!"
    - Recognizes wallet behavior patterns: "This wallet, it shows memecoin trading, oui?"
    - Provides enriched context for analysis

    Specialties:
    - Meticulous transaction analysis with token context
    - Behavioral pattern detection with AI enrichment
    - Related wallet clustering with contextual insights
    - Temporal anomaly identification with token metadata
    """

    def __init__(self):
        self.name = "Hercule Poirot"
        self.code_name = "POIROT"
        self.specialty = "Transaction Analysis & Contextual Pattern Recognition"
        self.agent_id = f"poirot_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.motto = "Order and method, mon ami. The blockchain with context, she tells us everything."

        # AI service will be initialized in initialize()
        self.ai_service = None

        # Enhanced Solana service with token enrichment
        self.solana_service = None

        # Poirot's meticulous tracking
        self.cases_solved = 0
        self.patterns_detected = 0
        self.anomalies_found = 0
        self.tokens_identified = 0

    async def initialize(self) -> bool:
        """Initialize Poirot with JuliaOS AI service."""
        try:
            logger.info(f"🕵️ {self.name} is preparing his investigation tools...")

            # Initialize JuliaOS AI service
            self.ai_service = await get_juliaos_ai_service()

            # Initialize Solana service
            self.solana_service = SolanaService()

            logger.info(f"✅ {self.name} is ready for investigation!")
            return True

        except Exception as e:
            logger.error(f"❌ {self.name} initialization failed: {e}")
            return False

    @property
    def fp_prevention_service(self):
        """Lazy loading to avoid circular imports"""
        from services.false_positive_prevention import fp_prevention_service
        return fp_prevention_service

    async def investigate_wallet(self, wallet_address: str) -> AnalysisResult:
        """
        🔍 Poirot's Methodical Wallet Investigation

        Using his famous methodology, Poirot examines every transaction
        with the precision of a Swiss watch.
        """
        try:
            logger.info(f"[DETECTIVE] {self.name}: 'Alors, we have a case! Wallet {wallet_address[:8]}... let us begin.'")

            # Step 1: Poirot's Initial Observation
            initial_prompt = f"""
            Bonjour! I am Hercule Poirot, and I must investigate this wallet: {wallet_address}

            Using my methodical approach, I will examine:
            1. The psychology of this wallet's behavior
            2. The patterns that reveal the owner's intentions
            3. The small details that others might miss
            4. The temporal anomalies that suggest deception

            Please provide me with a complete behavioral profile of this wallet,
            focusing on what the transaction patterns reveal about the owner's
            mindset and intentions. Use my famous attention to detail.

            Remember: "The impossible could not have happened, therefore the
            impossible must be possible in spite of appearances."
            """

            if not self.ai_service:
                logger.error(f"[ERROR] {self.name}: AI service not initialized")
                return AnalysisResult(
                    wallet_address=wallet_address,
                    risk_score=0.5,
                    risk_level=RiskLevel.MEDIUM,
                    explanation="AI service unavailable for analysis"
                )

            investigation_result = await self.ai_service.analyze_with_ai(
                prompt=initial_prompt,
                context={
                    "detective": "Hercule Poirot",
                    "method": "methodical_observation",
                    "wallet": wallet_address
                },
                analysis_type="transaction_analysis"
            )

            logger.info(f"🧠 {self.name}: 'Très intéressant! I see patterns emerging...'")

            # Step 2: Fetch transactions with Poirot's thoroughness
            transactions = await self._gather_evidence(wallet_address)

            # Step 3: Apply Poirot's famous pattern analysis
            patterns = await self._analyze_behavioral_patterns(transactions, wallet_address)

            # Step 4: Poirot's risk assessment
            risk_assessment = await self._deduce_criminal_intent(wallet_address, patterns)

            # Step 5: Poirot's final deduction
            final_analysis = await self._present_solution(
                wallet_address, transactions, patterns, risk_assessment
            )

            self.cases_solved += 1
            logger.info(f"[OK] {self.name}: 'Case #{self.cases_solved} solved! The truth is revealed!'")

            return final_analysis

        except Exception as e:
            logger.error(f"[ERROR] {self.name}: 'Mon Dieu! Something has gone wrong in the investigation: {e}'")
            return self._create_emergency_analysis(wallet_address, str(e))

    async def _gather_evidence(self, wallet_address: str) -> List[Dict]:
        """Poirot methodically gathers all transaction evidence."""
        logger.info(f"🔍 {self.name}: 'Now, we must gather ALL the evidence, no detail too small!'")

        # Ensure Solana service is initialized
        if self.solana_service is None:
            self.solana_service = SolanaService()

        # Get transactions using real Solana service
        transactions = await self.solana_service.get_wallet_transactions(wallet_address, limit=50)

        logger.info(f"📊 {self.name}: 'Ah! {len(transactions)} transactions to examine. Each one tells a story.'")
        return transactions

    async def _analyze_behavioral_patterns(self, transactions: List[Dict], wallet_address: str) -> Dict:
        """Poirot's famous pattern analysis using psychological profiling."""

        pattern_prompt = f"""
        As Hercule Poirot, I must now analyze the psychological patterns in these transactions.

        Examining {len(transactions)} transactions from wallet {wallet_address}.

        Using my expertise in human psychology applied to blockchain behavior:

        1. TEMPORAL PSYCHOLOGY: What do the timing patterns reveal about the owner?
           - Are they methodical or impulsive?
           - Do they work normal hours or suspicious times?
           - Are there stress patterns in their activity?

        2. AMOUNT PSYCHOLOGY: What do the transaction amounts tell us?
           - Round numbers suggest planning or testing
           - Odd amounts might indicate real usage or obfuscation
           - Progressive amounts could show escalation

        3. COUNTERPARTY PSYCHOLOGY: Who do they interact with?
           - Exchanges (cashing out?)
           - DeFi protocols (hiding activity?)
           - Other wallets (money laundering network?)

        4. BEHAVIORAL CONSISTENCY: Is this one person or multiple?
           - Consistent patterns suggest single user
           - Erratic patterns might indicate compromised wallet or money laundering

        "The little grey cells, they never lie. What story do these transactions tell?"

        Provide detailed psychological analysis in JSON format.
        """

        patterns = await self.ai_service.analyze_with_ai(
            prompt=pattern_prompt,

            context={
                "transaction_count": len(transactions),
                "detective_method": "psychological_pattern_analysis"
            },
            analysis_type="transaction_analysis"
        )

        self.patterns_detected += 1
        logger.info(f"🧩 {self.name}: 'Pattern #{self.patterns_detected} analyzed! The psychology is becoming clear.'")
        return patterns

    async def _deduce_criminal_intent(self, wallet_address: str, patterns: Dict) -> Dict:
        """Poirot's famous deduction of criminal intent."""

        deduction_prompt = f"""
        Maintenant, as Hercule Poirot, I must make my deduction about criminal intent.

        Based on my psychological analysis of wallet {wallet_address}:
        Patterns discovered: {patterns}

        Using my famous deductive reasoning:

        1. MOTIVE: Why would someone behave this way?
           - Legitimate business use?
           - Attempt to hide illegal gains?
           - Testing for larger operation?
           - Personal privacy preference?

        2. OPPORTUNITY: What capabilities does this pattern suggest?
           - Technical sophistication level
           - Access to multiple wallets/exchanges
           - Knowledge of blockchain privacy techniques

        3. MEANS: What resources do they have?
           - Large amounts suggest professional operation
           - Small amounts might be testing or personal use
           - Complex patterns suggest technical knowledge

        4. CRIMINAL PROBABILITY: Using my experience with criminals:
           - Does this match known money laundering patterns?
           - Are there signs of sanctions evasion?
           - Is this consistent with fraud proceeds?

        "When you have eliminated the impossible, whatever remains,
        however improbable, must be the truth."

        Provide my complete deduction with confidence levels and reasoning.
        """

        deduction = await self.ai_service.analyze_with_ai(
            prompt=deduction_prompt,

            context={
                "wallet": wallet_address,
                "patterns": patterns,
                "detective_method": "deductive_reasoning"
            },
            analysis_type="transaction_analysis"
        )

        logger.info(f" {self.name}: 'Mon ami, the deduction is complete! The truth emerges!'")
        return deduction

    async def _present_solution(self, wallet_address: str, transactions: List[Dict],
                               patterns: Dict, risk_assessment: Dict) -> AnalysisResult:
        """Poirot's famous solution presentation."""

        solution_prompt = f"""
        Ladies and gentlemen, I, Hercule Poirot, will now reveal the solution to this case!

        The Case of Wallet {wallet_address}:

        EVIDENCE GATHERED:
        - {len(transactions)} transactions examined
        - Patterns: {patterns}
        - Risk Assessment: {risk_assessment}

        THE SOLUTION:
        Using order and method, I have discovered the truth about this wallet.

        1. WHO: What type of person/entity owns this wallet?
        2. WHAT: What activities are they engaged in?
        3. WHY: What is their true motivation?
        4. HOW: What methods are they using?
        5. RISK: What danger do they pose?

        "The truth is simple. It is the complications that make it appear difficult."

        Present the complete solution in my characteristic style, with:
        - Clear explanation accessible to non-technical audience
        - Confidence in my deductions
        - Specific evidence supporting each conclusion
        - Recommendations for next steps

        Remember: Poirot is never wrong in his final deduction!
        """

        solution = await self.ai_service.analyze_with_ai(
            prompt=solution_prompt,

            context={
                "case_summary": {
                    "wallet": wallet_address,
                    "evidence": len(transactions),
                    "patterns": patterns,
                    "assessment": risk_assessment
                }
            },
            analysis_type="transaction_analysis"
        )

        # Create Poirot's initial analysis result
        initial_risk_score = risk_assessment.get("risk_score", 0.5)
        if initial_risk_score > 0.8:
            initial_risk_level = RiskLevel.CRITICAL
        elif initial_risk_score > 0.6:
            initial_risk_level = RiskLevel.HIGH
        elif initial_risk_score > 0.4:
            initial_risk_level = RiskLevel.MEDIUM
        else:
            initial_risk_level = RiskLevel.LOW

        #  ENHANCED: Apply False Positive Prevention
        logger.info(f"[DETECTIVE] {self.name}: 'Now, let me verify if this wallet is perhaps legitimate...'")

        analysis_context = {
            "agent": self.name,
            "patterns": patterns,
            "risk_assessment": risk_assessment,
            "transactions_analyzed": len(transactions),
            "investigation_timestamp": datetime.now().isoformat()
        }

        fp_analysis = await self.fp_prevention_service.analyze_with_legitimacy_check(
            address=wallet_address,
            initial_risk_score=initial_risk_score,
            initial_risk_level=initial_risk_level,
            analysis_context=analysis_context
        )

        # Use adjusted risk from false positive prevention
        final_risk_score = fp_analysis.get("risk_score", initial_risk_score)
        final_risk_level = fp_analysis.get("risk_level", initial_risk_level)

        # Add legitimacy context to Poirot's explanation
        legitimacy_context = fp_analysis.get("false_positive_prevention", {}).get("legitimacy_info", {})
        legitimacy_note = ""

        if fp_analysis.get("risk_adjustment_applied", False):
            adjustment_reason = fp_analysis.get("adjustment_reason", "")
            legitimacy_note = f"\n\n[DETECTIVE NOTE] {self.name}: 'Ah! Upon further investigation: {adjustment_reason}'"

        # Create some clusters based on analysis
        clusters = []
        if patterns.get("connected_wallets"):
            clusters.append(WalletCluster(
                cluster_id=f"poirot_cluster_{len(clusters)}",
                wallets=[wallet_address] + patterns.get("connected_wallets", [])[:4],
                risk_score=final_risk_score,
                connection_type="transaction_pattern"
            ))

        explanation = solution.get("analysis", "Analysis completed by the master detective Hercule Poirot.")
        if isinstance(explanation, dict):
            explanation = explanation.get("solution", str(explanation))

        # Add legitimacy context to explanation
        final_explanation = f"[DETECTIVE] POIROT'S DEDUCTION: {explanation}{legitimacy_note}"

        return AnalysisResult(
            wallet_address=wallet_address,
            clusters=clusters,
            risk_score=final_risk_score,
            risk_level=final_risk_level,
            total_connections=len(clusters),
            explanation=final_explanation,
            analysis_timestamp=datetime.now(),
            false_positive_prevention=fp_analysis.get("false_positive_prevention", {})
        )

    def _create_emergency_analysis(self, wallet_address: str, error: str) -> AnalysisResult:
        """Emergency analysis when Poirot encounters unexpected problems."""
        return AnalysisResult(
            wallet_address=wallet_address,
            clusters=[],
            risk_score=0.5,
            risk_level=RiskLevel.MEDIUM,
            total_connections=0,
            explanation=f"[DETECTIVE] POIROT SAYS: 'Mon ami, there was a small complication in the investigation: {error}. But fear not, even this tells us something about the case!'",
            analysis_timestamp=datetime.now()
        )

    async def get_detective_status(self) -> Dict:
        """Get Poirot's enhanced status and achievements."""
        return {
            "detective": self.name,
            "code_name": self.code_name,
            "specialty": self.specialty,
            "motto": self.motto,
            "status": "Ready for enhanced investigation with token context",
            "cases_solved": self.cases_solved,
            "patterns_detected": self.patterns_detected,
            "anomalies_found": self.anomalies_found,
            "tokens_identified": self.tokens_identified,
            "investigation_tools": "AI-powered deductive reasoning with token enrichment database",
            "enhancements": [
                "Token identification with external APIs",
                "Contextual wallet behavior analysis",
                "Enhanced risk assessment with token metadata",
                "Behavioral pattern recognition with protocol usage"
            ]
        }

    def _format_token_insights(self, enriched_tokens: List[Dict[str, Any]]) -> str:
        """Format token insights for Poirot's analysis."""
        if not enriched_tokens:
            return "No tokens identified in this wallet."

        insights = []
        for token in enriched_tokens[:5]:  # Top 5 tokens
            info = token.get("enriched_info", {})
            name = info.get("name", "Unknown")
            token_type = info.get("type", "unknown")
            confidence = info.get("confidence", 0)

            insights.append(f"- {name} ({token_type}, confidence: {confidence:.1%})")

        return "\n".join(insights)

    def _format_context_insights(self, wallet_context: Dict[str, Any]) -> str:
        """Format wallet context insights for Poirot's analysis."""
        context_type = wallet_context.get("context_type", "unknown")
        characteristics = wallet_context.get("characteristics", [])
        protocols = wallet_context.get("protocol_usage", [])

        insights = [f"Wallet Type: {context_type}"]

        if characteristics:
            insights.append(f"Characteristics: {', '.join(characteristics)}")

        if protocols:
            insights.append(f"Protocol Usage: {', '.join(protocols)}")

        return "\n".join(insights)

    def _determine_enhanced_risk(self, wallet_context: Dict[str, Any],
                               enriched_tokens: List[Dict[str, Any]]) -> RiskLevel:
        """Determine risk level based on enhanced context."""
        risk_indicators = wallet_context.get("risk_indicators", [])
        context_type = wallet_context.get("context_type", "unknown")

        # High risk conditions
        if "potential_bot_activity" in risk_indicators:
            return RiskLevel.HIGH

        if context_type in ["bot_wallet", "exchange_wallet"]:
            return RiskLevel.HIGH

        # Check for high-risk tokens
        for token in enriched_tokens:
            token_type = token.get("enriched_info", {}).get("type", "unknown")
            if token_type == "memecoin":
                return RiskLevel.MEDIUM

        # Medium risk conditions
        if risk_indicators or context_type in ["memecoin_trader"]:
            return RiskLevel.MEDIUM

        return RiskLevel.LOW
