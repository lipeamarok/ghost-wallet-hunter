"""
False Positive Prevention Service
Prevents false positives by cross-referencing analysis results with legitimacy databases
"""

import asyncio
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
from enum import Enum

from .blacklist_checker import BlacklistChecker
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from services.ghost_a2a_client import RiskLevel

logger = logging.getLogger(__name__)


class LegitimacyLevel(Enum):
    """Legitimacy confidence levels."""
    VERIFIED_OFFICIAL = "verified_official"      # 0.9+ confidence
    VERIFIED_COMMUNITY = "verified_community"    # 0.7-0.9 confidence
    KNOWN_PROJECT = "known_project"              # 0.5-0.7 confidence
    UNKNOWN = "unknown"                          # < 0.5 confidence
    SUSPICIOUS = "suspicious"                    # Blacklisted


class FalsePositivePreventionService:
    def __init__(self):
        self.blacklist_checker = BlacklistChecker()
        self._whitelist_service = None
        self._solscan_service = None
        self.prevention_stats = {
            "total_checks": 0,
            "false_positives_prevented": 0,
            "risk_adjustments_made": 0,
            "legitimacy_confirmations": 0
        }

    @property
    def whitelist_service(self):
        """Lazy load whitelist service to avoid circular imports."""
        if self._whitelist_service is None:
            from .whitelist_service import whitelist_service
            self._whitelist_service = whitelist_service
        return self._whitelist_service

    @property
    def solscan_service(self):
        """Lazy load solscan service to avoid circular imports."""
        if self._solscan_service is None:
            from .solscan_service import solscan_service
            self._solscan_service = solscan_service
        return self._solscan_service

    async def analyze_with_legitimacy_check(
        self,
        address: str,
        initial_risk_score: float,
        initial_risk_level: RiskLevel,
        analysis_context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Analyze address with comprehensive legitimacy checking to prevent false positives.

        Args:
            address: Wallet/token address to analyze
            initial_risk_score: Risk score from agents (0.0 to 1.0)
            initial_risk_level: Risk level from agents
            analysis_context: Context from the original analysis

        Returns:
            Adjusted analysis with legitimacy information
        """
        try:
            self.prevention_stats["total_checks"] += 1

            # Step 1: Get legitimacy information from all sources
            legitimacy_info = await self._get_comprehensive_legitimacy(address)

            # Step 2: Determine legitimacy level
            legitimacy_level = self._determine_legitimacy_level(legitimacy_info)

            # Step 3: Adjust risk based on legitimacy
            adjusted_analysis = await self._adjust_risk_based_on_legitimacy(
                address,
                initial_risk_score,
                initial_risk_level,
                legitimacy_level,
                legitimacy_info,
                analysis_context
            )

            # Step 4: Add prevention metadata
            adjusted_analysis["false_positive_prevention"] = {
                "legitimacy_level": legitimacy_level.value,
                "legitimacy_info": legitimacy_info,
                "original_risk_score": initial_risk_score,
                "original_risk_level": str(initial_risk_level),
                "adjustment_applied": adjusted_analysis["risk_adjustment_applied"],
                "confidence_in_adjustment": adjusted_analysis["adjustment_confidence"],
                "checked_at": datetime.now().isoformat()
            }

            return adjusted_analysis

        except Exception as e:
            logger.error(f" Error in false positive prevention for {address}: {e}")
            # Return original analysis if prevention fails
            return {
                "address": address,
                "risk_score": initial_risk_score,
                "risk_level": initial_risk_level,
                "risk_adjustment_applied": False,
                "adjustment_confidence": 0.0,
                "error": str(e),
                "false_positive_prevention": {
                    "error": str(e),
                    "fallback_used": True
                }
            }

    async def _get_comprehensive_legitimacy(self, address: str) -> Dict[str, Any]:
        """Get legitimacy information from all available sources."""

        # Run all checks concurrently
        tasks = [
            self.whitelist_service.check_address_legitimacy(address),
            self.solscan_service.check_address_verification(address),
            self.blacklist_checker.check_address(address)
        ]

        try:
            whitelist_result, solscan_result, blacklist_result = await asyncio.gather(
                *tasks, return_exceptions=True
            )
        except Exception as e:
            logger.error(f" Error gathering legitimacy data: {e}")
            whitelist_result = {"is_legitimate": False, "confidence": 0.0}
            solscan_result = {"is_verified": False, "confidence": 0.0}
            blacklist_result = {"is_blacklisted": False, "risk_score": 0.0}

        # Handle exceptions in results
        if isinstance(whitelist_result, Exception):
            logger.warning(f" Whitelist check failed: {whitelist_result}")
            whitelist_result = {"is_legitimate": False, "confidence": 0.0}

        if isinstance(solscan_result, Exception):
            logger.warning(f" Solscan check failed: {solscan_result}")
            solscan_result = {"is_verified": False, "confidence": 0.0}

        if isinstance(blacklist_result, Exception):
            logger.warning(f" Blacklist check failed: {blacklist_result}")
            blacklist_result = {"is_blacklisted": False, "risk_score": 0.0}

        return {
            "whitelist": whitelist_result,
            "solscan": solscan_result,
            "blacklist": blacklist_result,
            "aggregated_at": datetime.now().isoformat()
        }

    def _determine_legitimacy_level(self, legitimacy_info: Dict[str, Any]) -> LegitimacyLevel:
        """Determine overall legitimacy level from all sources."""

        whitelist = legitimacy_info.get("whitelist", {})
        solscan = legitimacy_info.get("solscan", {})
        blacklist = legitimacy_info.get("blacklist", {})

        # Check if blacklisted first
        if blacklist.get("is_blacklisted", False):
            return LegitimacyLevel.SUSPICIOUS

        # Calculate combined confidence
        whitelist_confidence = whitelist.get("confidence", 0.0)
        solscan_confidence = solscan.get("confidence", 0.0)

        # Weight the confidences (whitelist is more reliable for our use case)
        combined_confidence = (whitelist_confidence * 0.7) + (solscan_confidence * 0.3)

        # Determine level based on confidence and verification flags
        is_official = (
            whitelist.get("verification_level") == "official" or
            solscan.get("is_official", False)
        )

        is_verified = (
            whitelist.get("is_legitimate", False) or
            solscan.get("is_verified", False)
        )

        if combined_confidence >= 0.9 and is_official:
            return LegitimacyLevel.VERIFIED_OFFICIAL
        elif combined_confidence >= 0.7 and is_verified:
            return LegitimacyLevel.VERIFIED_COMMUNITY
        elif combined_confidence >= 0.5:
            return LegitimacyLevel.KNOWN_PROJECT
        else:
            return LegitimacyLevel.UNKNOWN

    async def _adjust_risk_based_on_legitimacy(
        self,
        address: str,
        original_risk_score: float,
        original_risk_level: RiskLevel,
        legitimacy_level: LegitimacyLevel,
        legitimacy_info: Dict[str, Any],
        analysis_context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Adjust risk assessment based on legitimacy findings."""

        adjusted_score = original_risk_score
        adjusted_level = original_risk_level
        adjustment_applied = False
        adjustment_confidence = 0.0
        adjustment_reason = ""

        # Define adjustment rules based on legitimacy level
        if legitimacy_level == LegitimacyLevel.VERIFIED_OFFICIAL:
            # Highly trusted official projects - significant risk reduction
            if original_risk_score > 0.3:
                adjusted_score = max(0.1, original_risk_score * 0.2)
                adjustment_applied = True
                adjustment_confidence = 0.95
                adjustment_reason = "Verified official project - risk significantly reduced"
                self.prevention_stats["false_positives_prevented"] += 1

        elif legitimacy_level == LegitimacyLevel.VERIFIED_COMMUNITY:
            # Community verified projects - moderate risk reduction
            if original_risk_score > 0.4:
                adjusted_score = max(0.2, original_risk_score * 0.4)
                adjustment_applied = True
                adjustment_confidence = 0.85
                adjustment_reason = "Community verified project - risk moderately reduced"
                self.prevention_stats["false_positives_prevented"] += 1

        elif legitimacy_level == LegitimacyLevel.KNOWN_PROJECT:
            # Known projects - slight risk reduction
            if original_risk_score > 0.6:
                adjusted_score = max(0.3, original_risk_score * 0.6)
                adjustment_applied = True
                adjustment_confidence = 0.70
                adjustment_reason = "Known project - risk slightly reduced"

        elif legitimacy_level == LegitimacyLevel.SUSPICIOUS:
            # Blacklisted - increase risk
            adjusted_score = min(1.0, original_risk_score + 0.3)
            adjustment_applied = True
            adjustment_confidence = 0.90
            adjustment_reason = "Address found in blacklist - risk increased"

        # Convert adjusted score to risk level
        if adjustment_applied:
            adjusted_level = self._score_to_risk_level(adjusted_score)
            self.prevention_stats["risk_adjustments_made"] += 1

        # Track legitimacy confirmations
        if legitimacy_level in [LegitimacyLevel.VERIFIED_OFFICIAL, LegitimacyLevel.VERIFIED_COMMUNITY]:
            self.prevention_stats["legitimacy_confirmations"] += 1

        return {
            "address": address,
            "risk_score": adjusted_score,
            "risk_level": adjusted_level,
            "risk_adjustment_applied": adjustment_applied,
            "adjustment_confidence": adjustment_confidence,
            "adjustment_reason": adjustment_reason,
            "legitimacy_context": self._create_legitimacy_context(legitimacy_level, legitimacy_info),
            "original_analysis": analysis_context
        }

    def _score_to_risk_level(self, score: float) -> str:
        """Convert risk score to RiskLevel string."""
        if score >= 0.8:
            return RiskLevel.CRITICAL
        elif score >= 0.6:
            return RiskLevel.HIGH
        elif score >= 0.4:
            return RiskLevel.MEDIUM
        else:
            return RiskLevel.LOW

    def _create_legitimacy_context(self, legitimacy_level: LegitimacyLevel, legitimacy_info: Dict) -> str:
        """Create human-readable legitimacy context."""

        whitelist = legitimacy_info.get("whitelist", {})
        solscan = legitimacy_info.get("solscan", {})

        if legitimacy_level == LegitimacyLevel.VERIFIED_OFFICIAL:
            token_info = whitelist.get("token_info") or solscan.get("token_info")
            if token_info:
                name = token_info.get("name", "Unknown")
                symbol = token_info.get("symbol", "UNK")
                return f"This is the official address for {name} ({symbol}), a verified project."
            else:
                return "This is a verified official address or program."

        elif legitimacy_level == LegitimacyLevel.VERIFIED_COMMUNITY:
            return "This address belongs to a community-verified project."

        elif legitimacy_level == LegitimacyLevel.KNOWN_PROJECT:
            return "This address is associated with a known project or token."

        elif legitimacy_level == LegitimacyLevel.SUSPICIOUS:
            return " This address appears in security blacklists and should be treated with caution."

        else:
            return "No legitimacy information available for this address."

    async def quick_legitimacy_check(self, address: str) -> Tuple[bool, float, str]:
        """
        Quick legitimacy check for simple true/false decisions.

        Returns:
            (is_legitimate, confidence, context)
        """
        try:
            legitimacy_info = await self._get_comprehensive_legitimacy(address)
            legitimacy_level = self._determine_legitimacy_level(legitimacy_info)

            is_legitimate = legitimacy_level in [
                LegitimacyLevel.VERIFIED_OFFICIAL,
                LegitimacyLevel.VERIFIED_COMMUNITY,
                LegitimacyLevel.KNOWN_PROJECT
            ]

            # Calculate overall confidence
            whitelist_conf = legitimacy_info.get("whitelist", {}).get("confidence", 0.0)
            solscan_conf = legitimacy_info.get("solscan", {}).get("confidence", 0.0)
            combined_confidence = (whitelist_conf * 0.7) + (solscan_conf * 0.3)

            context = self._create_legitimacy_context(legitimacy_level, legitimacy_info)

            return is_legitimate, combined_confidence, context

        except Exception as e:
            logger.error(f" Error in quick legitimacy check: {e}")
            return False, 0.0, f"Error checking legitimacy: {e}"

    async def get_prevention_stats(self) -> Dict[str, Any]:
        """Get false positive prevention statistics."""
        return {
            **self.prevention_stats,
            "prevention_rate": (
                self.prevention_stats["false_positives_prevented"] /
                max(1, self.prevention_stats["total_checks"])
            ) * 100,
            "last_updated": datetime.now().isoformat()
        }


# Global instance
fp_prevention_service = FalsePositivePreventionService()
