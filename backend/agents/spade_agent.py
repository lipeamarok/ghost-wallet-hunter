"""
Ghost Wallet Hunter - Sam Spade (Risk Assessment Agent)

Sam Spade - O detetive durão de San Francisco que faz julgamentos rápidos
e precisos sobre riscos. Não tem tempo para delicadezas.
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime

from services.smart_ai_service import get_ai_service
from .shared_models import RiskLevel

logger = logging.getLogger(__name__)


class SpadeAgent:
    """
    🚬 SAM SPADE - Risk Assessment Detective

    The tough San Francisco detective who doesn't waste time with small talk.
    Spade assesses risks directly and precisely, without letting emotions
    interfere with judgment. Expert at quickly classifying the danger level
    that each wallet represents.

    Specialties:
    - Quick and accurate risk assessment
    - Threat level classification
    - Criminal profile analysis
    - Immediate action recommendations
    """

    def __init__(self):
        self.name = "Sam Spade"
        self.code_name = "SPADE"
        self.specialty = "Risk Assessment & Threat Classification"
        self.agent_id = f"spade_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.motto = "When you're slapped, you'll take it and like it."
        self.location = "San Francisco (Digital)"

        # Real AI service for risk analysis
        self.ai_service = get_ai_service()

        # Spade's tough tracking
        self.risks_assessed = 0
        self.threats_classified = 0
        self.cases_closed = 0

    async def initialize(self) -> bool:
        """Initialize Sam Spade with his no-nonsense approach."""
        try:
            logger.info(f"🚬 {self.name} lights a cigarette and gets ready for business...")

            # Test AI connection with Spade's direct style
            test_result = await self.ai_service.analyze_with_ai(
                prompt="Spade here. I need to know if this system can handle some serious risk assessment work. No sugar-coating.",
                user_id=self.agent_id,
                analysis_type="transaction_analysis"
            )

            if "error" not in test_result:
                logger.info(f"✅ {self.name}: 'Good. The tools work. Let's get down to business.'")
                return True
            else:
                logger.error(f"❌ {self.name}: 'Great. Another system that doesn't work when you need it.'")
                return False

        except Exception as e:
            logger.error(f"❌ {self.name} initialization failed: {e}")
            return False

    async def assess_wallet_risk(self, wallet_address: str, evidence: Dict) -> Dict:
        """
        🎯 Spade's Direct Risk Assessment

        No beating around the bush. Spade looks at the evidence and
        gives it to you straight - is this wallet dangerous or not?
        """
        try:
            logger.info(f"🚬 {self.name}: 'Alright sweetheart, let's see what we're dealing with here...'")

            # Spade's direct risk assessment prompt
            risk_prompt = f"""
            Listen here, partner. I'm Sam Spade, and I don't have time for games.

            I need a straight risk assessment on this wallet: {wallet_address}

            Here's what I've got to work with:
            Evidence: {evidence}

            I need answers to these questions, and I need them fast:

            1. IMMEDIATE THREAT LEVEL:
               - Is this wallet actively dangerous right now?
               - What's the worst thing it could be doing?
               - Do we need to sound alarms or can we keep watching?

            2. CRIMINAL PROBABILITY:
               - Scale of 1-10, how likely is this criminal activity?
               - What type of crime are we probably looking at?
               - Is this small-time or big league?

            3. FINANCIAL RISK:
               - How much damage could this wallet do?
               - Are we talking petty cash or serious money?
               - What's the exposure if this goes bad?

            4. URGENCY ASSESSMENT:
               - Do we act now or keep investigating?
               - What happens if we wait too long?
               - What's the worst-case scenario timeline?

            5. ACTIONABLE INTELLIGENCE:
               - What should law enforcement know?
               - Who else needs to be warned?
               - What evidence do we need to nail this?

            I don't want maybes or perhapses. Give me hard numbers, clear categories,
            and straight talk. Lives and money are on the line.

            "The cheaper the crook, the gaudier the patter." - What's this wallet's patter telling us?

            Lay it on me straight, no chaser.
            """

            risk_assessment = await self.ai_service.analyze_with_ai(
                prompt=risk_prompt,
                user_id=self.agent_id,
                context={
                    "detective": "Sam Spade",
                    "assessment_type": "direct_risk_evaluation",
                    "evidence": evidence,
                    "wallet": wallet_address
                },
                analysis_type="transaction_analysis"
            )

            self.risks_assessed += 1
            logger.info(f"🎯 {self.name}: 'Risk assessment #{self.risks_assessed} complete. Here's the score.'")

            return risk_assessment

        except Exception as e:
            logger.error(f"❌ {self.name}: 'Damn it! Risk assessment failed: {e}'")
            return {"error": f"Risk assessment failed: {e}", "risk_level": "UNKNOWN"}

    async def classify_threat_level(self, wallet_data: Dict, patterns: Dict) -> Dict:
        """Spade's threat classification using street-smart experience."""

        threat_prompt = f"""
        Alright, time to classify this threat. I've seen every type of operator in this city.

        Wallet profile: {wallet_data}
        Detected patterns: {patterns}

        Based on my years working these streets, I need to classify this threat:

        1. THREAT CATEGORY:
           - PETTY CRIMINAL: Small-time operator, minor threat
           - ORGANIZED CRIME: Professional operation, serious threat
           - TERRORIST FINANCE: National security concern, maximum threat
           - INSIDER TRADING: White-collar crime, regulatory threat
           - MONEY LAUNDERING: Financial crime, moderate to high threat
           - INNOCENT CITIZEN: No threat, false alarm

        2. SOPHISTICATION LEVEL:
           - AMATEUR: Sloppy, easy to catch, low danger
           - PROFESSIONAL: Knows what they're doing, moderate danger
           - EXPERT: High-tech, hard to catch, high danger
           - STATE-SPONSORED: Government backing, extreme danger

        3. OPERATIONAL STATUS:
           - DORMANT: Not currently active, monitoring required
           - ACTIVE: Currently operating, investigation warranted
           - ESCALATING: Increasing activity, urgent attention needed
           - CRITICAL: Immediate action required, all hands on deck

        4. RESOURCE ASSESSMENT:
           - What kind of money are we talking about?
           - How much damage could they do?
           - What's their operational capacity?

        I've busted everyone from pickpockets to mob bosses. Where does this operator fit?

        Give me a classification I can act on, not some academic theory.
        """

        threat_classification = await self.ai_service.analyze_with_ai(
            prompt=threat_prompt,
            user_id=self.agent_id,
            context={
                "classification_type": "threat_assessment",
                "wallet_data": wallet_data,
                "patterns": patterns
            },
            analysis_type="transaction_analysis"
        )

        self.threats_classified += 1
        logger.info(f"🚨 {self.name}: 'Threat #{self.threats_classified} classified. We know what we're dealing with.'")

        return threat_classification

    async def recommend_actions(self, risk_data: Dict, threat_data: Dict) -> Dict:
        """Spade's action recommendations based on his street experience."""

        action_prompt = f"""
        Time for action recommendations. I don't give advice, I give orders.

        Risk Assessment: {risk_data}
        Threat Classification: {threat_data}

        Based on what I'm seeing, here's what needs to happen:

        1. IMMEDIATE ACTIONS (Next 24 hours):
           - What needs to happen right now?
           - Who needs to be notified immediately?
           - What evidence needs to be secured?

        2. SHORT-TERM ACTIONS (Next week):
           - What investigation steps are needed?
           - What additional monitoring should be set up?
           - Who else needs to be brought in?

        3. LONG-TERM STRATEGY (Next month):
           - How do we build the case?
           - What resources will we need?
           - What's the end game here?

        4. CONTINGENCY PLANS:
           - What if they get wise to us?
           - What if the situation escalates?
           - What's our backup plan?

        5. RESOURCE ALLOCATION:
           - How many people do we need on this?
           - What's the priority level?
           - Where should this fit in the queue?

        I've been doing this long enough to know what works and what doesn't.
        These recommendations need to be practical, actionable, and effective.

        "Don't be too sure I'm as crooked as I'm supposed to be." -
        Sometimes the obvious answer is wrong. What's the smart play here?

        Give me a plan I can take to the chief.
        """

        action_plan = await self.ai_service.analyze_with_ai(
            prompt=action_prompt,
            user_id=self.agent_id,
            context={
                "recommendation_type": "action_plan",
                "risk_data": risk_data,
                "threat_data": threat_data
            },
            analysis_type="transaction_analysis"
        )

        logger.info(f"📋 {self.name}: 'Action plan ready. Let's move on this.'")

        return action_plan

    async def final_risk_report(self, wallet_address: str, all_assessments: Dict) -> Dict:
        """Spade's final risk report - direct and actionable."""

        final_prompt = f"""
        Final report time. The chief wants the bottom line on wallet {wallet_address}.

        All assessment data: {all_assessments}

        Here's what the chief needs to know:

        1. THE VERDICT:
           - Is this wallet a threat or not?
           - What confidence level do I have in this assessment?
           - What's my professional recommendation?

        2. THE EVIDENCE:
           - What solid evidence supports this conclusion?
           - What would hold up in court?
           - What's circumstantial vs. concrete?

        3. THE RISK:
           - What's the worst-case scenario?
           - What's the most likely outcome?
           - What's our exposure if we're wrong?

        4. THE ACTION:
           - What should happen next?
           - Who needs to know about this?
           - What's the timeline for action?

        5. THE FOLLOW-UP:
           - How do we monitor this going forward?
           - What would change our assessment?
           - When do we review this case again?

        I've been working these cases for years. This assessment needs to be:
        - Clear enough for a jury to understand
        - Detailed enough for law enforcement to act on
        - Honest enough to stake my reputation on

        "When a man's partner is killed, he's supposed to do something about it."
        Well, when a wallet is dirty, we're supposed to do something about it too.

        Give me a report I can sign my name to.
        """

        final_report = await self.ai_service.analyze_with_ai(
            prompt=final_prompt,
            user_id=self.agent_id,
            context={
                "report_type": "final_risk_assessment",
                "all_assessments": all_assessments,
                "wallet": wallet_address
            },
            analysis_type="transaction_analysis"
        )

        self.cases_closed += 1
        logger.info(f"✅ {self.name}: 'Case #{self.cases_closed} closed. Report filed and ready for action.'")

        return final_report

    def calculate_risk_score(self, assessment_data: Dict) -> float:
        """Spade's risk scoring based on street-smart experience."""
        try:
            # Extract risk indicators from assessment
            threat_level = assessment_data.get("threat_level", "MEDIUM")
            criminal_probability = assessment_data.get("criminal_probability", 5)
            sophistication = assessment_data.get("sophistication_level", "PROFESSIONAL")
            operational_status = assessment_data.get("operational_status", "ACTIVE")

            # Spade's scoring system (0.0 to 1.0)
            base_score = 0.5

            # Threat level adjustment
            if threat_level == "CRITICAL":
                base_score += 0.3
            elif threat_level == "HIGH":
                base_score += 0.2
            elif threat_level == "LOW":
                base_score -= 0.2

            # Criminal probability (1-10 scale)
            base_score += (criminal_probability - 5) * 0.05

            # Sophistication adjustment
            if sophistication == "EXPERT":
                base_score += 0.1
            elif sophistication == "AMATEUR":
                base_score -= 0.1

            # Operational status
            if operational_status == "CRITICAL":
                base_score += 0.15
            elif operational_status == "DORMANT":
                base_score -= 0.15

            # Keep within bounds
            risk_score = max(0.0, min(1.0, base_score))

            logger.info(f"🎯 {self.name}: 'Risk score calculated: {risk_score:.2f}. That's my professional assessment.'")
            return risk_score

        except Exception as e:
            logger.error(f"❌ {self.name}: 'Risk scoring failed: {e}. Defaulting to medium risk.'")
            return 0.5

    def get_risk_level_from_score(self, risk_score: float) -> RiskLevel:
        """Convert numeric risk score to risk level classification."""
        if risk_score >= 0.8:
            return RiskLevel("CRITICAL")
        elif risk_score >= 0.6:
            return RiskLevel("HIGH")
        elif risk_score >= 0.4:
            return RiskLevel("MEDIUM")
        else:
            return RiskLevel("LOW")

    async def get_detective_status(self) -> Dict:
        """Get Sam Spade's current status and track record."""
        return {
            "detective": self.name,
            "code_name": self.code_name,
            "specialty": self.specialty,
            "motto": self.motto,
            "location": self.location,
            "status": "Ready to assess threats and take names",
            "risks_assessed": self.risks_assessed,
            "threats_classified": self.threats_classified,
            "cases_closed": self.cases_closed,
            "assessment_tools": "AI-enhanced street-smart analysis",
            "signature_method": "Direct risk evaluation with no BS",
            "current_mood": "Professional skepticism with a side of cynicism",
            "favorite_drink": "Whiskey, neat",
            "agent_id": self.agent_id
        }
