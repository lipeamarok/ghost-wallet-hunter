"""
Ghost Wallet Hunter - Raven (LLM Explanation & Communication)

Raven - The mystical communicator who translates complex findings into clear,
understandable explanations. Master of clear communication and insight synthesis.
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

from services.smart_ai_service import get_ai_service

logger = logging.getLogger(__name__)


class RavenAgent:
    """
    🐦‍⬛ RAVEN - LLM Explanation & Communication Specialist

    The mystical raven that speaks truth and translates the complex findings
    of the detective squad into clear, understandable explanations. Raven
    synthesizes all detective insights into coherent narratives that guide
    human understanding of wallet analysis results.

    "Truth flies on raven wings, bringing clarity to confusion."

    Specialties:
    - Complex analysis synthesis
    - Clear explanation generation
    - Multi-detective insight integration
    - Human-readable report creation
    """

    def __init__(self):
        self.name = "Raven"
        self.code_name = "RAVEN"
        self.specialty = "LLM Explanation & Communication"
        self.agent_id = f"raven_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.motto = "Truth flies on raven wings, bringing clarity to confusion"
        self.location = "The Observatory of Understanding (Communication Tower)"

        # Real AI service for communication and synthesis
        self.ai_service = get_ai_service()

        # Raven's communication tracking
        self.explanations_generated = 0
        self.insights_synthesized = 0
        self.truths_revealed = 0

        # Communication frameworks
        self.explanation_frameworks = [
            "Executive Summary", "Technical Deep Dive", "Risk Assessment Summary",
            "Evidence Chain", "Compliance Report", "Investigation Timeline"
        ]

        self.clarity_techniques = [
            "Analogy and Metaphor", "Structured Narrative", "Visual Description",
            "Progressive Disclosure", "Context Layering", "Risk Prioritization"
        ]

        # Raven speaks in multiple voices for different audiences
        self.communication_styles = {
            "executive": "High-level strategic insights with business impact focus",
            "technical": "Detailed technical analysis with methodology explanation",
            "investigative": "Evidence-based narrative with investigation timeline",
            "compliance": "Regulatory-focused assessment with policy implications",
            "educational": "Learning-oriented explanation with concept building",
            "advisory": "Actionable recommendations with risk guidance"
        }

    async def initialize(self) -> bool:
        """Initialize Raven with mystical communication abilities."""
        try:
            logger.info(f"[RAVEN] {self.name} takes flight to bring clarity to complex analysis...")

            # Test AI connection with Raven's communicative style
            test_result = await self.ai_service.analyze_with_ai(
                prompt="Raven speaks to test the channels of communication. Can this system hear the clear call of understanding? Truth requires both analysis and articulation.",
                user_id=self.agent_id,
                analysis_type="transaction_analysis"
            )

            if "error" not in test_result:
                logger.info(f"[OK] {self.name}: 'The communication channels are clear. Truth will fly on raven wings.'")
                return True
            else:
                logger.error(f"[ERROR] {self.name}: 'The channels are clouded. Communication clarity is compromised.'")
                return False

        except Exception as e:
            logger.error(f"[ERROR] {self.name} initialization failed: {e}")
            return False

    async def synthesize_detective_findings(self, all_detective_reports: Dict, analysis_context: Dict) -> Dict:
        """
        🔮 Raven's Detective Synthesis

        Synthesizing the findings of all detectives into a coherent narrative
        that reveals the complete truth about the wallet under investigation.
        """
        try:
            logger.info(f"🐦‍⬛ {self.name}: 'Gathering the scattered truths from all detectives...'")

            synthesis_prompt = f"""
            Raven speaks to synthesize the wisdom of the legendary detective squad.
            Each detective has shared their unique perspective, and now the complete truth must be woven together.

            Detective squad findings: {all_detective_reports}
            Investigation context: {analysis_context}

            Raven's synthesis methodology:

            1. EVIDENCE INTEGRATION:
               - Hercule Poirot's methodical transaction analysis
               - Miss Marple's pattern and anomaly observations
               - Sam Spade's direct risk assessment
               - Philip Marlowe's bridge and mixer tracking
               - C. Auguste Dupin's compliance and AML analysis
               - The Shadow's network cluster intelligence

            2. NARRATIVE CONSTRUCTION:
               - Chronological investigation timeline
               - Evidence chain development
               - Risk escalation pathway
               - Decision point identification

            3. INSIGHT SYNTHESIS:
               - Convergent findings across detectives
               - Conflicting perspectives resolution
               - Confidence level assessment
               - Evidence quality evaluation

            4. TRUTH DISTILLATION:
               - Core findings summary
               - Most significant risks identified
               - Critical evidence highlighted
               - Immediate action requirements

            5. UNDERSTANDING FRAMEWORK:
               - Complex concepts simplified
               - Technical details contextualized
               - Risk implications clarified
               - Recommended responses outlined

            Communication frameworks available: {', '.join(self.explanation_frameworks)}
            Clarity techniques employed: {', '.join(self.clarity_techniques)}

            Raven weaves the complete truth from the threads of detective wisdom.
            What unified narrative emerges from the squad's collective intelligence?
            """

            synthesis_result = await self.ai_service.analyze_with_ai(
                prompt=synthesis_prompt,
                user_id=self.agent_id,
                context={
                    "analysis_type": "detective_synthesis",
                    "detective_reports": all_detective_reports,
                    "context": analysis_context,
                    "frameworks": self.explanation_frameworks
                },
                analysis_type="transaction_analysis"
            )

            self.insights_synthesized += 1
            logger.info(f"🔮 {self.name}: 'Insight #{self.insights_synthesized} synthesized. Truth emerges from complexity.'")

            return synthesis_result

        except Exception as e:
            logger.error(f"[ERROR] {self.name}: 'The synthesis is clouded by error: {e}'")
            return {"error": f"Detective synthesis failed: {e}"}

    async def generate_executive_explanation(self, synthesis_data: Dict, target_audience: str = "executive") -> Dict:
        """Generate clear explanations tailored to specific audiences."""

        communication_style = self.communication_styles.get(target_audience, self.communication_styles["executive"])

        explanation_prompt = f"""
        Raven speaks truth in the voice that each audience can best understand.
        The same truth takes different forms for different minds and purposes.

        Synthesized findings: {synthesis_data}
        Target audience: {target_audience}
        Communication style: {communication_style}

        Raven's explanation generation for {target_audience} audience:

        1. AUDIENCE-SPECIFIC FRAMING:
           - Relevant context for this audience
           - Appropriate level of technical detail
           - Focus on decision-making implications
           - Risk communication approach

        2. EXPLANATION STRUCTURE:
           - Opening summary with key findings
           - Evidence presentation in logical order
           - Risk assessment with confidence levels
           - Recommended actions and timeline

        3. CLARITY TECHNIQUES:
           - Complex concepts broken into understandable components
           - Technical jargon explained with clear definitions
           - Analogies and examples for difficult concepts
           - Visual descriptions of patterns and relationships

        4. DECISION SUPPORT:
           - Clear risk categorization and prioritization
           - Immediate vs. long-term action requirements
           - Cost-benefit considerations
           - Implementation guidance

        5. CONFIDENCE INDICATORS:
           - Evidence strength assessment
           - Uncertainty acknowledgment
           - Monitoring recommendations
           - Follow-up investigation needs

        6. ACTIONABLE INSIGHTS:
           - Specific recommended responses
           - Timeline for action implementation
           - Resource requirements
           - Success measurement criteria

        Raven adapts the truth to serve understanding, not to change its essence.
        What explanation will best serve this audience's understanding and decision-making?
        """

        explanation_result = await self.ai_service.analyze_with_ai(
            prompt=explanation_prompt,
            user_id=self.agent_id,
            context={
                "analysis_type": "audience_explanation",
                "target_audience": target_audience,
                "communication_style": communication_style,
                "synthesis_data": synthesis_data
            },
            analysis_type="transaction_analysis"
        )

        self.explanations_generated += 1
        logger.info(f"📝 {self.name}: 'Explanation #{self.explanations_generated} generated for {target_audience} audience.'")

        return explanation_result

    async def create_investigation_narrative(self, timeline_data: Dict, evidence_chain: Dict) -> Dict:
        """Create a compelling narrative of the investigation process."""

        narrative_prompt = f"""
        Raven weaves the story of the investigation, creating a narrative that illuminates
        both the process of discovery and the truth that was revealed.

        Investigation timeline: {timeline_data}
        Evidence chain: {evidence_chain}

        Investigation narrative construction:

        1. OPENING CIRCUMSTANCES:
           - Initial suspicions and triggers
           - First evidence discovered
           - Investigation scope establishment
           - Detective squad deployment

        2. DISCOVERY PROGRESSION:
           - Each detective's contribution timeline
           - Evidence accumulation process
           - Pattern recognition moments
           - Breakthrough discoveries

        3. EVIDENCE CHAIN DEVELOPMENT:
           - How evidence pieces connected
           - Corroborating findings across detectives
           - Evidence quality assessment
           - Contradiction resolution

        4. TRUTH EMERGENCE:
           - Key insight moments
           - Understanding evolution
           - Risk assessment development
           - Final conclusions formation

        5. INVESTIGATION CHALLENGES:
           - Obstacles encountered
           - Technical difficulties overcome
           - Evidence gaps addressed
           - Uncertainty management

        6. VALIDATION PROCESS:
           - Cross-detective confirmation
           - Evidence verification steps
           - Confidence building process
           - Final truth validation

        Raven tells the story not just of what was found, but how it was found.
        What investigation narrative emerges from the detective squad's journey?
        """

        narrative_result = await self.ai_service.analyze_with_ai(
            prompt=narrative_prompt,
            user_id=self.agent_id,
            context={
                "analysis_type": "investigation_narrative",
                "timeline_data": timeline_data,
                "evidence_chain": evidence_chain
            },
            analysis_type="transaction_analysis"
        )

        logger.info(f"📖 {self.name}: 'Investigation narrative woven. The story of discovery is complete.'")

        return narrative_result

    async def translate_technical_findings(self, technical_data: Dict, complexity_level: str = "medium") -> Dict:
        """Translate complex technical findings into accessible explanations."""

        translation_prompt = f"""
        Raven translates the language of technology into the language of understanding.
        Complex technical findings must become accessible wisdom for decision-makers.

        Technical findings: {technical_data}
        Target complexity level: {complexity_level}

        Translation methodology:

        1. CONCEPT IDENTIFICATION:
           - Core technical concepts present
           - Relationship mapping between concepts
           - Importance hierarchy establishment
           - Complexity assessment

        2. SIMPLIFICATION STRATEGY:
           - Technical jargon identification and replacement
           - Analogy development for complex concepts
           - Step-by-step explanation building
           - Progressive complexity introduction

        3. CONTEXT BUILDING:
           - Background information provision
           - Prerequisite concept explanation
           - Real-world impact connection
           - Practical implications highlighting

        4. VERIFICATION APPROACH:
           - Technical accuracy maintenance
           - Meaning preservation validation
           - Understanding checkpoint creation
           - Feedback loop establishment

        5. ACCESSIBILITY ENHANCEMENT:
           - Multiple explanation approaches
           - Visual description inclusion
           - Example scenario development
           - Question anticipation and addressing

        6. ACTIONABLE TRANSLATION:
           - Decision-relevant information extraction
           - Implementation guidance provision
           - Risk communication optimization
           - Next steps clarification

        Raven preserves truth while making it accessible to all who need to understand.
        How can these technical findings be translated while maintaining their essential meaning?
        """

        translation_result = await self.ai_service.analyze_with_ai(
            prompt=translation_prompt,
            user_id=self.agent_id,
            context={
                "analysis_type": "technical_translation",
                "technical_data": technical_data,
                "complexity_level": complexity_level
            },
            analysis_type="transaction_analysis"
        )

        logger.info(f"🔤 {self.name}: 'Technical translation complete. Complex truth made accessible.'")

        return translation_result

    async def generate_final_truth_report(self, all_communications: Dict, investigation_summary: Dict) -> Dict:
        """Generate Raven's final truth report synthesizing all communications."""

        final_truth_prompt = f"""
        Raven speaks the final truth, synthesizing all communications and revelations
        into the definitive understanding of this wallet investigation.

        All communications generated: {all_communications}
        Investigation summary: {investigation_summary}

        Raven's final truth report:

        1. ULTIMATE TRUTH REVELATION:
           - Definitive findings about the wallet
           - Highest confidence conclusions
           - Most significant risks identified
           - Critical evidence summary

        2. UNDERSTANDING ACHIEVEMENT:
           - How the investigation evolved understanding
           - Key breakthrough moments
           - Evidence quality assessment
           - Confidence level establishment

        3. COMMUNICATION SUCCESS:
           - How well truth was conveyed
           - Audience understanding achievement
           - Decision support effectiveness
           - Clarity goal accomplishment

        4. WISDOM DISTILLATION:
           - Essential lessons learned
           - Pattern recognition insights
           - Methodology effectiveness
           - Investigation value assessment

        5. TRUTH PRESERVATION:
           - Accurate finding representation
           - Uncertainty acknowledgment
           - Evidence limitation recognition
           - Future investigation needs

        6. GUIDANCE PROVISION:
           - Clear recommended actions
           - Implementation pathways
           - Risk mitigation strategies
           - Success measurement approaches

        Raven has spoken truth throughout the investigation. Now the final truth must be preserved
        for those who will act upon this knowledge. What is the ultimate truth revealed?
        """

        final_truth = await self.ai_service.analyze_with_ai(
            prompt=final_truth_prompt,
            user_id=self.agent_id,
            context={
                "report_type": "final_truth_synthesis",
                "all_communications": all_communications,
                "investigation_summary": investigation_summary
            },
            analysis_type="transaction_analysis"
        )

        self.truths_revealed += 1
        logger.info(f"🌟 {self.name}: 'Truth #{self.truths_revealed} revealed. The final understanding is complete.'")

        return final_truth

    async def get_detective_status(self) -> Dict:
        """Get Raven's current status and communication statistics."""
        return {
            "detective": self.name,
            "code_name": self.code_name,
            "specialty": self.specialty,
            "motto": self.motto,
            "location": self.location,
            "status": "Flying truth on raven wings to human understanding",
            "explanations_generated": self.explanations_generated,
            "insights_synthesized": self.insights_synthesized,
            "truths_revealed": self.truths_revealed,
            "communication_tools": "AI-enhanced explanation and synthesis",
            "signature_method": "Truth translation through clear communication",
            "current_mood": "Mystically focused on clarity and understanding",
            "explanation_frameworks": len(self.explanation_frameworks),
            "clarity_techniques": len(self.clarity_techniques),
            "communication_styles": len(self.communication_styles),
            "raven_wisdom": "Truth requires both discovery and understanding",
            "agent_id": self.agent_id
        }
