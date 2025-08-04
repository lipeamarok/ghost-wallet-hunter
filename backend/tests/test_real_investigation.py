#!/usr/bin/env python3
"""
🔍 Real Investigation Test Script
Ghost Wallet Hunter - Test com carteira real para verificar o Risk Scoring System

Este script faz uma investigação real de uma carteira e mostra:
1. Como os detetives estão pontuando
2. Quais detetives estão efetivamente contribuindo
3. Como o cálculo ponderado funciona na prática
4. Se override está sendo aplicado quando necessário
"""

import asyncio
import json
import sys
import logging
from datetime import datetime

# Add project root to path
sys.path.append('.')

from agents.detective_squad import DetectiveSquadManager

# Configure logging for detailed output
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class RealInvestigationTester:
    """
    🔍 Testador de Investigação Real
    """
    
    def __init__(self):
        self.detective_squad = DetectiveSquadManager()
        
    async def initialize(self):
        """Initialize the detective squad"""
        logger.info("🚀 Initializing Detective Squad...")
        success = await self.detective_squad.initialize_squad()
        if not success:
            logger.error("❌ Failed to initialize detective squad")
            return False
        logger.info("✅ Detective Squad ready!")
        return True
    
    async def investigate_wallet(self, wallet_address: str):
        """Investigate a real wallet and analyze the scoring"""
        logger.info(f"🔍 Starting investigation of: {wallet_address}")
        logger.info("=" * 80)
        
        try:
            # Perform full investigation
            result = await self.detective_squad.investigate_wallet_comprehensive(wallet_address)
            
            # Analyze the results
            await self.analyze_investigation_results(wallet_address, result)
            
            return result
            
        except Exception as e:
            logger.error(f"❌ Investigation failed: {e}")
            return None
    
    async def analyze_investigation_results(self, wallet_address: str, result: Dict):
        """Analyze and display investigation results in detail"""
        
        if "error" in result:
            logger.error(f"❌ Investigation error: {result['error']}")
            return
        
        # Extract key information
        legendary_results = result.get("legendary_results", {})
        consensus = legendary_results.get("legendary_consensus", {})
        detective_findings = legendary_results.get("detective_findings", {})
        transparency = legendary_results.get("transparency_report", {})
        
        # Display main results
        logger.info("🎯 INVESTIGATION RESULTS")
        logger.info("-" * 40)
        logger.info(f"Wallet: {wallet_address}")
        logger.info(f"Risk Score: {consensus.get('consensus_risk_score', 'N/A')}")
        logger.info(f"Risk Level: {consensus.get('consensus_risk_level', 'N/A')}")
        logger.info(f"Threat Classification: {consensus.get('threat_classification', 'N/A')}")
        logger.info(f"Detective Consensus: {consensus.get('detective_consensus', 'N/A')}")
        logger.info(f"Override Triggered: {consensus.get('override_triggered', False)}")
        
        if consensus.get('override_triggered'):
            logger.warning(f"⚠️ Override Reason: {consensus.get('override_reason', 'N/A')}")
        
        # Analyze which detectives contributed
        logger.info("\n🕵️ DETECTIVE CONTRIBUTIONS")
        logger.info("-" * 40)
        
        detective_scores = {}
        
        # Check each detective
        detectives = {
            "Poirot": detective_findings.get("poirot_transaction_analysis"),
            "Marple": detective_findings.get("marple_pattern_detection"),
            "Spade": detective_findings.get("spade_risk_assessment"),
            "Marlowe": detective_findings.get("marlowe_bridge_tracking"),
            "Dupin": detective_findings.get("dupin_compliance_analysis"),
            "Shadow": detective_findings.get("shadow_network_intelligence")
        }
        
        for name, report in detectives.items():
            if report:
                score = self.extract_detective_score(name, report)
                if score is not None:
                    detective_scores[name] = score
                    logger.info(f"✅ {name}: {score:.3f}")
                else:
                    logger.warning(f"⚠️ {name}: Investigated but no valid score")
            else:
                logger.info(f"❌ {name}: No investigation")
        
        # Show transparency report
        logger.info("\n📊 TRANSPARENCY REPORT")
        logger.info("-" * 40)
        
        weights = transparency.get("agent_weights_used", {})
        top_contributors = transparency.get("top_contributors", [])
        critical_flags = transparency.get("critical_flags_detected", 0)
        calculation_method = transparency.get("calculation_method", "N/A")
        
        logger.info(f"Scoring Method: {calculation_method}")
        logger.info(f"Critical Flags: {critical_flags}")
        
        if top_contributors:
            logger.info("Top Risk Contributors:")
            for i, (agent, score) in enumerate(top_contributors, 1):
                weight = weights.get(agent, 1.0)
                logger.info(f"  {i}. {agent.capitalize()}: {score:.3f} (weight: {weight})")
        
        # Calculate what the score SHOULD be manually
        logger.info("\n🧮 MANUAL CALCULATION VERIFICATION")
        logger.info("-" * 40)
        
        total_weighted = 0
        total_weights = 0
        
        agent_weights = {
            "poirot": 1.0,
            "marple": 1.0,
            "spade": 1.2,
            "marlowe": 0.9,
            "dupin": 1.3,
            "shadow": 0.8
        }
        
        for detective, score in detective_scores.items():
            agent_name = detective.lower()
            weight = agent_weights.get(agent_name, 1.0)
            confidence = 0.8  # Default confidence
            
            # Apply confidence adjustment
            adjusted_weight = weight * (0.7 + 0.3 * confidence)
            weighted_score = score * adjusted_weight
            
            total_weighted += weighted_score
            total_weights += adjusted_weight
            
            logger.info(f"{detective}: {score:.3f} × {adjusted_weight:.3f} = {weighted_score:.3f}")
        
        if total_weights > 0:
            manual_score = total_weighted / total_weights
            logger.info(f"\nManual Calculation: {total_weighted:.3f} ÷ {total_weights:.3f} = {manual_score:.3f}")
            
            actual_score = consensus.get('consensus_risk_score', 0)
            difference = abs(manual_score - actual_score)
            
            if difference < 0.01:
                logger.info(f"✅ Calculation matches! (difference: {difference:.4f})")
            else:
                logger.warning(f"⚠️ Calculation differs by {difference:.3f}")
                logger.warning(f"   Expected: {manual_score:.3f}")
                logger.warning(f"   Actual: {actual_score:.3f}")
        
        # Analysis summary
        logger.info("\n📋 ANALYSIS SUMMARY")
        logger.info("-" * 40)
        
        contributing_detectives = len(detective_scores)
        total_detectives = 7
        
        logger.info(f"Detectives Contributing: {contributing_detectives}/{total_detectives}")
        logger.info(f"Score Transparency: {'✅ Clear' if top_contributors else '⚠️ Limited'}")
        logger.info(f"Override System: {'✅ Active' if consensus.get('override_triggered') else '⏸️ Not triggered'}")
        
        if contributing_detectives < 3:
            logger.warning("⚠️ WARNING: Few detectives contributed to the score!")
            logger.warning("   This may indicate data availability issues.")
        
        if contributing_detectives >= 5:
            logger.info("✅ Good detective coverage for reliable scoring")
    
    def extract_detective_score(self, detective_name: str, report: any) -> float:
        """Extract risk score from detective report"""
        try:
            if detective_name == "Poirot":
                if hasattr(report, 'risk_score'):
                    return float(report.risk_score)
                return None
                
            elif detective_name in ["Marple", "Spade", "Marlowe"]:
                if isinstance(report, dict):
                    return report.get('risk_score')
                return None
                
            elif detective_name == "Dupin":
                if isinstance(report, dict):
                    compliance_report = report.get('compliance_report', {})
                    status = compliance_report.get('compliance_status', '')
                    if status == 'NON-COMPLIANT':
                        return 0.95
                    elif status == 'COMPLIANT':
                        return 0.1
                    elif status == 'PENDING':
                        return 0.5
                return None
                
            elif detective_name == "Shadow":
                if isinstance(report, dict) and 'analysis' in report:
                    analysis_text = report['analysis']
                    if '"risk_score":' in analysis_text:
                        # Parse JSON to extract risk_score
                        start = analysis_text.find('"risk_score":') + len('"risk_score":')
                        end = analysis_text.find(',', start)
                        if end == -1:
                            end = analysis_text.find('}', start)
                        try:
                            return float(analysis_text[start:end].strip())
                        except:
                            pass
                return None
                
        except Exception as e:
            logger.error(f"Error extracting score for {detective_name}: {e}")
            return None
        
        return None

async def main():
    """Main test function"""
    print("🔍 Ghost Wallet Hunter - Real Investigation Test")
    print("=" * 80)
    
    # Test wallets
    test_wallets = [
        "4k9EJp9vtf95b4pTnTi5v3fKtTkkhzCDJkaD7Vv2FvGn",  # Previous test wallet
        # Add more test wallets here if needed
    ]
    
    # Initialize tester
    tester = RealInvestigationTester()
    
    # Initialize squad
    if not await tester.initialize():
        print("❌ Failed to initialize detective squad")
        return 1
    
    # Test each wallet
    for wallet in test_wallets:
        print(f"\n🎯 Testing wallet: {wallet}")
        print("=" * 80)
        
        result = await tester.investigate_wallet(wallet)
        
        if result:
            print("\n✅ Investigation completed successfully!")
        else:
            print("\n❌ Investigation failed!")
        
        print("\n" + "=" * 80)
    
    return 0

if __name__ == "__main__":
    # Run the test
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
