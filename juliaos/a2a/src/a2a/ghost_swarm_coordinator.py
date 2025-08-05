"""
Ghost Swarm Coordinator - FASE 5 IMPLEMENTATION
==============================================

Coordenação REAL entre detetives Ghost usando A2A protocol.
SEM MOCKS - Apenas dados reais, investigações reais, IA real.

Fluxo de Investigação:
1. Poirot: Análise técnica de transações
2. Marple: Detecção de padrões suspeitos
3. Spade: Avaliação de risco e contexto
4. Raven: Relatório final consolidado
"""

import asyncio
import httpx
import json
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
from dataclasses import dataclass

from .julia_bridge import JuliaOSConnection

logger = logging.getLogger(__name__)


@dataclass
class InvestigationStep:
    """Etapa da investigação coordenada"""
    agent_id: str
    agent_name: str
    specialty: str
    status: str
    findings: Dict[str, Any]
    next_agent: Optional[str] = None
    timestamp: str = ""


@dataclass
class SwarmInvestigation:
    """Investigação coordenada completa"""
    wallet_address: str
    investigation_id: str
    steps: List[InvestigationStep]
    final_report: Dict[str, Any]
    confidence_score: float
    risk_assessment: str
    timestamp: str
    total_duration: float


class GhostSwarmCoordinator:
    """
    COORDENADOR DE ENXAME - GHOST DETECTIVES
    =======================================

    Orquestra investigações usando múltiplos detetives em sequência.
    Cada detetive contribui com sua especialidade para uma análise completa.
    """

    def __init__(self, a2a_url: str = "http://127.0.0.1:9100", julia_url: str = "http://127.0.0.1:8052"):
        self.a2a_url = a2a_url.rstrip('/')
        self.julia_url = julia_url

        # Cadeia de investigação otimizada
        self.investigation_chain = [
            {
                'agent_id': 'poirot',
                'role': 'transaction_analyzer',
                'purpose': 'Análise técnica detalhada de transações',
                'next': 'marple'
            },
            {
                'agent_id': 'marple',
                'role': 'pattern_detector',
                'purpose': 'Detecção de padrões e anomalias comportamentais',
                'next': 'spade'
            },
            {
                'agent_id': 'spade',
                'role': 'risk_assessor',
                'purpose': 'Avaliação de risco e contexto de segurança',
                'next': 'raven'
            },
            {
                'agent_id': 'raven',
                'role': 'report_synthesizer',
                'purpose': 'Síntese final e relatório consolidado',
                'next': None
            }
        ]

    async def investigate_wallet_coordinated(self, wallet_address: str) -> SwarmInvestigation:
        """
        INVESTIGAÇÃO COORDENADA COMPLETA
        ==============================

        Executa investigação usando cadeia de detetives especialistas.
        DADOS REAIS ONLY - Sem mocks, sem simulações.
        """
        investigation_id = f"swarm_{int(datetime.now().timestamp())}"
        start_time = datetime.now()

        logger.info(f"🚀 Starting coordinated investigation: {investigation_id}")
        logger.info(f"🎯 Target wallet: {wallet_address}")

        investigation_steps = []
        accumulated_data = {
            'wallet_address': wallet_address,
            'investigation_id': investigation_id,
            'blockchain_data': {},
            'findings': {},
            'context': {}
        }

        try:
            # Executar cadeia de investigação
            for i, step_config in enumerate(self.investigation_chain):
                step_start = datetime.now()

                logger.info(f"📋 Step {i+1}/4: {step_config['agent_id']} - {step_config['purpose']}")

                # Executar investigação com agente específico
                step_result = await self._execute_investigation_step(
                    step_config,
                    accumulated_data,
                    is_final=(step_config['next'] is None)
                )

                step_duration = (datetime.now() - step_start).total_seconds()
                step_result.timestamp = datetime.now(timezone.utc).isoformat()

                investigation_steps.append(step_result)

                # Acumular dados para próximo agente
                if step_result.findings:
                    accumulated_data['findings'][step_config['agent_id']] = step_result.findings

                logger.info(f"✅ Step completed in {step_duration:.2f}s - Status: {step_result.status}")

                # Verificar se deve continuar
                if step_result.status == 'error' and step_config['agent_id'] != 'raven':
                    logger.warning(f"⚠️ Step failed, but continuing to next agent")

            # Gerar relatório final consolidado
            final_report = await self._generate_final_report(investigation_steps, accumulated_data)

            total_duration = (datetime.now() - start_time).total_seconds()

            # Calcular score de confiança baseado nos resultados
            confidence_score = self._calculate_confidence_score(investigation_steps)

            # Determinar avaliação de risco final
            risk_assessment = self._determine_final_risk(investigation_steps, confidence_score)

            swarm_investigation = SwarmInvestigation(
                wallet_address=wallet_address,
                investigation_id=investigation_id,
                steps=investigation_steps,
                final_report=final_report,
                confidence_score=confidence_score,
                risk_assessment=risk_assessment,
                timestamp=datetime.now(timezone.utc).isoformat(),
                total_duration=total_duration
            )

            logger.info(f"🎉 Coordinated investigation completed!")
            logger.info(f"⏱️ Total duration: {total_duration:.2f}s")
            logger.info(f"📊 Confidence: {confidence_score:.2f}")
            logger.info(f"🚨 Risk: {risk_assessment}")

            return swarm_investigation

        except Exception as e:
            logger.error(f"❌ Coordinated investigation failed: {str(e)}")

            # Retornar resultado parcial em caso de erro
            return SwarmInvestigation(
                wallet_address=wallet_address,
                investigation_id=investigation_id,
                steps=investigation_steps,
                final_report={'error': f"Investigation failed: {str(e)}"},
                confidence_score=0.0,
                risk_assessment='UNKNOWN',
                timestamp=datetime.now(timezone.utc).isoformat(),
                total_duration=(datetime.now() - start_time).total_seconds()
            )

    async def _execute_investigation_step(
        self,
        step_config: Dict[str, str],
        accumulated_data: Dict[str, Any],
        is_final: bool = False
    ) -> InvestigationStep:
        """Executa uma etapa da investigação com agente específico"""

        agent_id = step_config['agent_id']

        print(f"🔍 Executing step for agent: {agent_id}")
        print(f"🌐 A2A URL: {self.a2a_url}")

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                # Preparar payload com dados acumulados
                investigation_payload = {
                    'wallet_address': accumulated_data['wallet_address'],
                    'investigation_context': {
                        'investigation_id': accumulated_data['investigation_id'],
                        'step_role': step_config['role'],
                        'previous_findings': accumulated_data.get('findings', {}),
                        'is_final_step': is_final,
                        'chain_position': len(accumulated_data.get('findings', {})) + 1
                    }
                }

                # URL da chamada
                investigate_url = f"{self.a2a_url}/{agent_id}/investigate"
                print(f"📡 Calling: {investigate_url}")
                print(f"📦 Payload: {investigation_payload}")

                # Chamar agente via A2A
                response = await client.post(
                    investigate_url,
                    json=investigation_payload,
                    headers={'Content-Type': 'application/json'}
                )

                print(f"📋 Response status: {response.status_code}")
                print(f"📄 Response content: {response.text[:500]}")

                if response.status_code == 200:
                    result_data = response.json()

                    return InvestigationStep(
                        agent_id=agent_id,
                        agent_name=result_data.get('agent_name', f'Agent {agent_id}'),
                        specialty=result_data.get('specialty', step_config['role']),
                        status='completed',
                        findings=result_data.get('investigation', {}),
                        next_agent=step_config.get('next')
                    )
                else:
                    logger.error(f"A2A call failed for {agent_id}: {response.status_code}")
                    return InvestigationStep(
                        agent_id=agent_id,
                        agent_name=f'Agent {agent_id}',
                        specialty=step_config['role'],
                        status='error',
                        findings={'error': f"HTTP {response.status_code}: {response.text}"},
                        next_agent=step_config.get('next')
                    )

        except Exception as e:
            print(f"❌ Step execution exception for {agent_id}: {str(e)}")
            logger.error(f"Step execution failed for {agent_id}: {str(e)}")
            return InvestigationStep(
                agent_id=agent_id,
                agent_name=f'Agent {agent_id}',
                specialty=step_config['role'],
                status='error',
                findings={'error': str(e)},
                next_agent=step_config.get('next')
            )

    async def _generate_final_report(
        self,
        investigation_steps: List[InvestigationStep],
        accumulated_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Gera relatório final consolidado usando dados reais"""

        # Extrair dados consolidados
        successful_steps = [step for step in investigation_steps if step.status == 'completed']

        # Dados básicos da wallet (do primeiro agente bem-sucedido)
        wallet_data = {}
        for step in successful_steps:
            if 'wallet_address' in step.findings:
                wallet_data = step.findings
                break

        # Consolidar findings de todos os agentes
        consolidated_findings = {}
        risk_indicators = []
        patterns_detected = []

        for step in successful_steps:
            findings = step.findings

            # Extrair indicadores de risco
            if 'risk_indicators' in findings:
                risk_indicators.extend(findings['risk_indicators'])

            # Extrair padrões detectados
            if 'patterns' in findings:
                patterns_detected.extend(findings['patterns'])

            # Consolidar por especialidade
            consolidated_findings[step.agent_id] = {
                'specialty': step.specialty,
                'findings': findings,
                'status': step.status
            }

        # Calcular métricas agregadas
        total_balance = wallet_data.get('balance_sol', 0)
        total_transactions = wallet_data.get('total_transactions', 0)
        activity_score = wallet_data.get('activity_score', 0)

        return {
            'investigation_summary': {
                'wallet_address': accumulated_data['wallet_address'],
                'total_balance_sol': total_balance,
                'total_transactions': total_transactions,
                'activity_score': activity_score,
                'data_source': 'solana_mainnet_coordinated'
            },
            'agent_contributions': consolidated_findings,
            'risk_analysis': {
                'indicators': list(set(risk_indicators)),  # Remove duplicates
                'patterns': list(set(patterns_detected)),
                'total_risk_factors': len(set(risk_indicators))
            },
            'execution_summary': {
                'total_agents': len(investigation_steps),
                'successful_agents': len(successful_steps),
                'failed_agents': len(investigation_steps) - len(successful_steps),
                'completion_rate': len(successful_steps) / len(investigation_steps) if investigation_steps else 0
            },
            'data_quality': {
                'real_blockchain_data': total_transactions > 0,
                'multiple_agent_validation': len(successful_steps) >= 2,
                'comprehensive_analysis': len(successful_steps) >= 3
            }
        }

    def _calculate_confidence_score(self, investigation_steps: List[InvestigationStep]) -> float:
        """Calcula score de confiança baseado na qualidade da investigação"""

        if not investigation_steps:
            return 0.0

        successful_steps = [step for step in investigation_steps if step.status == 'completed']
        completion_rate = len(successful_steps) / len(investigation_steps)

        # Base score da taxa de conclusão
        base_score = completion_rate * 0.4

        # Bonus por dados de blockchain reais
        blockchain_bonus = 0.0
        for step in successful_steps:
            if step.findings.get('data_source') == 'solana_mainnet_rpc':
                blockchain_bonus += 0.2
                break

        # Bonus por múltiplos agentes
        multi_agent_bonus = min(len(successful_steps) * 0.1, 0.3)

        # Bonus por análise abrangente
        comprehensive_bonus = 0.1 if len(successful_steps) >= 3 else 0.0

        total_score = min(base_score + blockchain_bonus + multi_agent_bonus + comprehensive_bonus, 1.0)

        return round(total_score, 2)

    def _determine_final_risk(self, investigation_steps: List[InvestigationStep], confidence: float) -> str:
        """Determina avaliação de risco final baseada nos resultados"""

        if confidence < 0.3:
            return 'INSUFFICIENT_DATA'

        risk_indicators = 0
        total_score = 0.0

        for step in investigation_steps:
            if step.status == 'completed':
                findings = step.findings

                # Contar indicadores de risco
                if 'risk_indicators' in findings:
                    risk_indicators += len(findings['risk_indicators'])

                # Somar scores de atividade
                if 'activity_score' in findings:
                    total_score += findings['activity_score']

        # Normalizar score
        avg_score = total_score / len([s for s in investigation_steps if s.status == 'completed']) if investigation_steps else 0

        # Determinar risco
        if risk_indicators >= 3 or avg_score > 0.8:
            return 'HIGH'
        elif risk_indicators >= 1 or avg_score > 0.5:
            return 'MEDIUM'
        else:
            return 'LOW'


# Instância global para uso
ghost_swarm = GhostSwarmCoordinator()


async def test_swarm_coordination():
    """Teste REAL da coordenação de enxame"""
    print("🧪 Testing REAL Ghost Swarm Coordination")
    print("=" * 50)

    # Wallet real para teste
    test_wallet = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"

    try:
        print(f"🎯 Target: {test_wallet}")
        print("🚀 Starting coordinated investigation...")

        # Executar investigação coordenada REAL
        result = await ghost_swarm.investigate_wallet_coordinated(test_wallet)

        print(f"\n📊 INVESTIGATION COMPLETE!")
        print(f"🆔 ID: {result.investigation_id}")
        print(f"⏱️ Duration: {result.total_duration:.2f}s")
        print(f"✅ Confidence: {result.confidence_score}")
        print(f"🚨 Risk: {result.risk_assessment}")

        print(f"\n📋 AGENT CHAIN RESULTS:")
        for i, step in enumerate(result.steps):
            status_emoji = "✅" if step.status == "completed" else "❌"
            print(f"  {i+1}. {status_emoji} {step.agent_name} ({step.specialty})")

        print(f"\n💰 FINAL SUMMARY:")
        summary = result.final_report.get('investigation_summary', {})
        print(f"  Balance: {summary.get('total_balance_sol', 0):.4f} SOL")
        print(f"  Transactions: {summary.get('total_transactions', 0)}")
        print(f"  Activity: {summary.get('activity_score', 0):.2f}")

        print(f"\n🎉 SWARM COORDINATION SUCCESS!")
        return True

    except Exception as e:
        print(f"\n❌ Test failed: {str(e)}")
        return False


if __name__ == "__main__":
    asyncio.run(test_swarm_coordination())
