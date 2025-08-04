# backend/api/real_ai_investigation.py
"""
API de Investigação Real com IA
Endpoint que conecta dados reais da blockchain com agentes IA reais
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime

from ..services.juliaos_integration_service import JuliaOSIntegrationService
from ..services.real_blockchain_service import RealBlockchainService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/real-ai", tags=["Real AI Investigation"])

class WalletInvestigationRequest(BaseModel):
    wallet_address: str
    investigation_type: str = "comprehensive"
    max_transactions: int = 50
    include_network_analysis: bool = True

class InvestigationResponse(BaseModel):
    case_id: str
    status: str
    wallet_address: str
    investigation_type: str
    timestamp: str
    agents_used: List[str]
    blockchain_data: Dict[str, Any]
    ai_analysis: Dict[str, Any]
    confidence_level: float
    recommendations: List[str]

@router.post("/investigate", response_model=Dict[str, Any])
async def investigate_wallet_with_real_ai(
    request: WalletInvestigationRequest
) -> Dict[str, Any]:
    """
    Investigação COMPLETA de carteira com IA REAL

    1. Coleta dados REAIS da blockchain Solana
    2. Analisa com agentes IA REAIS (Julia + OpenAI GPT-4)
    3. Retorna investigação profissional completa
    """
    case_id = f"REAL_AI_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    logger.info(f"🚀 INVESTIGAÇÃO REAL INICIADA: {case_id} - Carteira: {request.wallet_address}")

    try:
        # Fase 1: Coletar dados REAIS da blockchain
        logger.info("📊 Fase 1: Coletando dados REAIS da blockchain Solana...")

        async with RealBlockchainService() as blockchain_service:
            # Coletar dados completos
            wallet_analysis = await blockchain_service.analyze_wallet_patterns(request.wallet_address)

            if wallet_analysis.get("error"):
                raise HTTPException(
                    status_code=400,
                    detail=f"Erro ao coletar dados da carteira: {wallet_analysis['error']}"
                )

            # Coletar carteiras conectadas se solicitado
            connected_wallets = []
            if request.include_network_analysis:
                connected_wallets = await blockchain_service.get_connected_wallets(
                    request.wallet_address, 15
                )

            logger.info(f"✅ Dados coletados: {wallet_analysis['transaction_count']} transações, {len(connected_wallets)} carteiras conectadas")

        # Fase 2: Análise com IA REAL (Agentes Julia + OpenAI GPT-4)
        logger.info("🤖 Fase 2: Análise com IA REAL (Agentes Julia + OpenAI GPT-4)...")

        async with JuliaOSIntegrationService() as julia_service:
            # Verificar saúde do sistema IA
            health = await julia_service.health_check()
            if health["status"] != "healthy":
                raise HTTPException(
                    status_code=503,
                    detail=f"Sistema IA não disponível: {health.get('error', 'Unknown error')}"
                )

            # Executar investigação colaborativa com IA REAL
            ai_investigation = await julia_service.conduct_full_investigation(
                wallet_address=request.wallet_address,
                transaction_data=wallet_analysis.get("transactions", []),
                connected_wallets=connected_wallets
            )

            if ai_investigation.get("error"):
                raise HTTPException(
                    status_code=500,
                    detail=f"Erro na análise IA: {ai_investigation['error']}"
                )

            logger.info("✅ Análise IA concluída com sucesso")

        # Fase 3: Compilar resultado final
        logger.info("📋 Fase 3: Compilando resultado final...")

        # Extrair recomendações da análise IA
        recommendations = extract_recommendations(ai_investigation)

        # Calcular score de risco final
        risk_score = calculate_risk_score(wallet_analysis, ai_investigation)

        # Resultado final da investigação
        final_result = {
            "case_id": case_id,
            "status": "completed",
            "wallet_address": request.wallet_address,
            "investigation_type": request.investigation_type,
            "timestamp": datetime.now().isoformat(),

            # Dados REAIS da blockchain
            "blockchain_data": {
                "account_info": wallet_analysis.get("account_info", {}),
                "transaction_count": wallet_analysis.get("transaction_count", 0),
                "token_accounts_count": wallet_analysis.get("token_accounts_count", 0),
                "temporal_patterns": wallet_analysis.get("temporal_patterns", {}),
                "value_patterns": wallet_analysis.get("value_patterns", {}),
                "interaction_patterns": wallet_analysis.get("interaction_patterns", {}),
                "token_patterns": wallet_analysis.get("token_patterns", {}),
                "risk_indicators": wallet_analysis.get("risk_indicators", []),
                "connected_wallets": connected_wallets,
                "transactions": wallet_analysis.get("transactions", [])[:10]  # Primeiras 10 para resposta
            },

            # Análise IA REAL
            "ai_analysis": {
                "agents_used": ai_investigation.get("agents_used", []),
                "detective_reports": ai_investigation.get("detective_reports", {}),
                "final_synthesis": ai_investigation.get("final_synthesis", {}),
                "confidence_level": ai_investigation.get("confidence_level", 0.0)
            },

            # Avaliação consolidada
            "risk_assessment": {
                "overall_risk_score": risk_score,
                "risk_level": get_risk_level(risk_score),
                "key_concerns": extract_key_concerns(wallet_analysis, ai_investigation),
                "risk_factors": wallet_analysis.get("risk_indicators", [])
            },

            # Recomendações acionáveis
            "recommendations": recommendations,

            # Metadados
            "metadata": {
                "investigation_duration_seconds": 0,  # Calcular se necessário
                "data_sources": ["solana_mainnet", "openai_gpt4", "juliaos_agents"],
                "analysis_completeness": calculate_completeness(wallet_analysis, ai_investigation),
                "confidence_level": ai_investigation.get("confidence_level", 0.0)
            }
        }

        logger.info(f"🎉 INVESTIGAÇÃO REAL CONCLUÍDA: {case_id}")
        logger.info(f"📊 Risk Score: {risk_score:.2f}, Level: {get_risk_level(risk_score)}")
        logger.info(f"🎯 Confidence: {ai_investigation.get('confidence_level', 0.0):.2f}")

        return final_result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro na investigação real {case_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno na investigação: {str(e)}"
        )

@router.get("/health")
async def check_real_ai_health():
    """Verifica saúde dos sistemas de IA real"""
    try:
        async with JuliaOSIntegrationService() as julia_service:
            julia_health = await julia_service.health_check()

        async with RealBlockchainService() as blockchain_service:
            # Teste simples de conectividade blockchain
            test_result = await blockchain_service.get_solana_account_info("11111111111111111111111111111112")
            blockchain_health = {"status": "healthy" if not test_result.get("error") else "unhealthy"}

        return {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "juliaos_ai": julia_health,
                "blockchain_data": blockchain_health
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.get("/agent-status")
async def get_ai_agent_status():
    """Status dos agentes IA Julia"""
    try:
        async with JuliaOSIntegrationService() as julia_service:
            agents = await julia_service.find_ghost_agents()
            return {
                "agents_found": len(agents),
                "agents": agents,
                "timestamp": datetime.now().isoformat()
            }
    except Exception as e:
        return {"error": str(e)}

def extract_recommendations(ai_investigation: Dict[str, Any]) -> List[str]:
    """Extrai recomendações da análise IA"""
    recommendations = []

    # Extrair de relatórios individuais
    reports = ai_investigation.get("detective_reports", {})

    # Recomendações do Spade (Risk Assessment)
    spade_report = reports.get("spade", {})
    if isinstance(spade_report, dict) and "recommendations" in spade_report:
        recommendations.extend(spade_report["recommendations"])

    # Recomendações da síntese final (Raven)
    synthesis = ai_investigation.get("final_synthesis", {})
    if isinstance(synthesis, dict) and "recommendations" in synthesis:
        recommendations.extend(synthesis["recommendations"])

    # Recomendações padrão baseadas em padrões
    if not recommendations:
        recommendations = [
            "Continue monitoring wallet activity",
            "Review transaction patterns for anomalies",
            "Consider additional compliance checks if needed"
        ]

    return recommendations[:5]  # Limitar a 5 recomendações

def calculate_risk_score(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> float:
    """Calcula score de risco final (0.0 a 1.0)"""
    risk_score = 0.0

    # Fatores baseados em dados blockchain
    risk_indicators = blockchain_data.get("risk_indicators", [])
    risk_score += len(risk_indicators) * 0.1

    # Idade da conta
    temporal_patterns = blockchain_data.get("temporal_patterns", {})
    timespan_days = temporal_patterns.get("total_timespan_days", 0)
    if timespan_days < 7:
        risk_score += 0.3
    elif timespan_days < 30:
        risk_score += 0.15

    # Volume de atividade vs saldo
    account_info = blockchain_data.get("account_info", {})
    balance_sol = account_info.get("balance_sol", 0)
    transaction_count = blockchain_data.get("transaction_count", 0)

    if balance_sol < 0.01 and transaction_count > 20:
        risk_score += 0.2

    # Fatores da análise IA
    confidence = ai_analysis.get("confidence_level", 0.5)
    if confidence < 0.3:
        risk_score += 0.2  # Baixa confiança aumenta risco

    # Normalizar entre 0.0 e 1.0
    return min(1.0, max(0.0, risk_score))

def get_risk_level(risk_score: float) -> str:
    """Converte score numérico em nível de risco"""
    if risk_score < 0.2:
        return "LOW"
    elif risk_score < 0.5:
        return "MEDIUM"
    elif risk_score < 0.8:
        return "HIGH"
    else:
        return "CRITICAL"

def extract_key_concerns(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> List[str]:
    """Extrai principais preocupações identificadas"""
    concerns = []

    # Preocupações baseadas em dados blockchain
    risk_indicators = blockchain_data.get("risk_indicators", [])
    for indicator in risk_indicators:
        if indicator == "VERY_NEW_ACCOUNT":
            concerns.append("Account created very recently (< 7 days)")
        elif indicator == "HIGH_ACTIVITY_VOLUME":
            concerns.append("Unusually high transaction volume")
        elif indicator == "HIGH_FAILURE_RATE":
            concerns.append("High rate of failed transactions")
        elif indicator == "LOW_BALANCE_HIGH_ACTIVITY":
            concerns.append("High activity with very low balance")

    # Preocupações da análise IA
    reports = ai_analysis.get("detective_reports", {})

    # Marple (pattern detection)
    marple_report = reports.get("marple", {})
    if isinstance(marple_report, dict) and "anomalies" in marple_report:
        concerns.append("Anomalous behavioral patterns detected")

    # Spade (risk assessment)
    spade_report = reports.get("spade", {})
    if isinstance(spade_report, dict) and "threat_level" in spade_report:
        threat_level = spade_report.get("threat_level", "UNKNOWN")
        if threat_level in ["HIGH", "CRITICAL"]:
            concerns.append(f"Risk assessment indicates {threat_level} threat level")

    return concerns[:5]  # Limitar a 5 preocupações principais

def calculate_completeness(blockchain_data: Dict[str, Any], ai_analysis: Dict[str, Any]) -> float:
    """Calcula completude da análise (0.0 a 1.0)"""
    completeness_score = 0.0

    # Verificar dados blockchain coletados
    if blockchain_data.get("account_info", {}).get("exists"):
        completeness_score += 0.2
    if blockchain_data.get("transaction_count", 0) > 0:
        completeness_score += 0.2
    if blockchain_data.get("token_accounts_count", 0) >= 0:
        completeness_score += 0.1

    # Verificar análises IA realizadas
    reports = ai_analysis.get("detective_reports", {})
    expected_agents = ["poirot", "marple", "spade", "shadow", "raven"]

    for agent in expected_agents:
        if agent in reports and not reports[agent].get("error"):
            completeness_score += 0.1

    return min(1.0, completeness_score)
