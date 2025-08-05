#!/usr/bin/env python3
"""
Ghost Detectives A2A Setup - FASE 4.1 (Simplificado)
=====================================================

Script para verificar e configurar detetives Ghost no sistema.
Versão simplificada usando serviços existentes.

REAL SETUP - Sem mocks, apenas chamadas reais.
"""

import asyncio
import json
import httpx
from datetime import datetime
from typing import Dict, List, Any


class SimpleJuliaOSConnection:
    """Conexão simples com Julia Server"""

    def __init__(self, julia_url: str = "http://127.0.0.1:8052"):
        self.julia_url = julia_url

    async def health_check(self) -> Dict[str, Any]:
        """Verifica se Julia Server está rodando"""
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(f"{self.julia_url}/health")
                if response.status_code == 200:
                    return response.json()
                else:
                    raise Exception(f"Health check failed: {response.status_code}")
            except Exception as e:
                raise Exception(f"Connection failed: {e}")

    async def list_agents(self) -> List[Dict[str, Any]]:
        """Lista todos os agentes"""
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(f"{self.julia_url}/api/v1/agents")
                if response.status_code == 200:
                    data = response.json()
                    return data.get("agents", [])
                else:
                    raise Exception(f"List agents failed: {response.status_code}")
            except Exception as e:
                raise Exception(f"List agents error: {e}")


class GhostDetectivesSetup:
    """Setup dos detetives Ghost"""

    def __init__(self):
        self.julia_conn = SimpleJuliaOSConnection()

        # Detetives esperados
        self.expected_detectives = {
            "poirot": "Detective Hercule Poirot",
            "marple": "Detective Miss Jane Marple",
            "spade": "Detective Sam Spade",
            "marlowee": "Detective Philip Marlowe",
            "dupin": "Detective C. Auguste Dupin",
            "shadow": "Detective The Shadow",
            "raven": "Detective Edgar Raven",
            "compliance": "Detective Compliance Officer"
        }

    async def check_julia_server(self) -> bool:
        """Verifica se Julia Server está rodando"""
        print("🔗 Checking Julia Server connection...")
        try:
            health = await self.julia_conn.health_check()
            print(f"   ✅ Julia Server: {health.get('service', 'JuliaOS')} - {health.get('status', 'active')}")
            return True
        except Exception as e:
            print(f"   ❌ Julia Server not available: {e}")
            print("   💡 Make sure Julia Server is running:")
            print("      cd juliaos && julia --project=. start_julia_server.jl")
            return False

    async def check_detectives(self) -> Dict[str, Any]:
        """Verifica quais detetives estão disponíveis"""
        print("\n🕵️ Checking available detectives...")

        try:
            agents = await self.julia_conn.list_agents()

            found_detectives = {}
            missing_detectives = []

            for detective_id, detective_name in self.expected_detectives.items():
                found = False
                for agent in agents:
                    if agent.get("id") == detective_id:
                        found_detectives[detective_id] = {
                            "name": agent.get("name", detective_name),
                            "status": "available",
                            "description": agent.get("description", ""),
                            "blueprint": agent.get("blueprint", {})
                        }
                        print(f"   ✅ {detective_name} ({detective_id})")
                        found = True
                        break

                if not found:
                    missing_detectives.append(detective_id)
                    print(f"   ❌ {detective_name} ({detective_id}) - NOT FOUND")

            return {
                "total_expected": len(self.expected_detectives),
                "found_count": len(found_detectives),
                "missing_count": len(missing_detectives),
                "found_detectives": found_detectives,
                "missing_detectives": missing_detectives,
                "all_agents": agents
            }

        except Exception as e:
            print(f"   ❌ Error checking detectives: {e}")
            return {"error": str(e)}

    async def setup_summary(self) -> Dict[str, Any]:
        """Gera sumário do setup"""
        print("\n🚀 Ghost Detectives A2A Setup")
        print("=" * 50)

        # Verificar Julia Server
        julia_ok = await self.check_julia_server()
        if not julia_ok:
            return {"status": "failed", "reason": "Julia Server not available"}

        # Verificar detetives
        detective_status = await self.check_detectives()

        if "error" in detective_status:
            return {"status": "failed", "reason": detective_status["error"]}

        # Resultado
        found = detective_status["found_count"]
        total = detective_status["total_expected"]
        missing = detective_status["missing_detectives"]

        print(f"\n📊 SETUP SUMMARY:")
        print(f"   ✅ Available detectives: {found}/{total}")

        if found == total:
            print("   🎉 ALL DETECTIVES READY FOR A2A!")
            status = "complete"
        elif found > 0:
            print(f"   ⚠️ Missing detectives: {missing}")
            print("   💡 Some detectives need to be created in Julia")
            status = "partial"
        else:
            print("   ❌ NO DETECTIVES FOUND")
            print("   💡 Check if Julia Server has detective definitions")
            status = "failed"

        setup_result = {
            "timestamp": datetime.now().isoformat(),
            "status": status,
            "julia_server": "connected",
            "detectives": detective_status,
            "a2a_ready": found > 0
        }

        # Salvar resultados
        with open("ghost_detectives_setup_results.json", "w") as f:
            json.dump(setup_result, f, indent=2)

        print(f"\n📄 Results saved to: ghost_detectives_setup_results.json")

        if status == "complete":
            print("\n🎉 FASE 4.1 COMPLETE - Ready for A2A Server (Fase 4.2)")
        elif status == "partial":
            print("\n⚠️ FASE 4.1 PARTIAL - Some detectives missing")
        else:
            print("\n❌ FASE 4.1 FAILED - Check Julia Server and detective definitions")

        return setup_result


async def main():
    """Executa setup dos Ghost Detectives"""
    setup = GhostDetectivesSetup()
    result = await setup.setup_summary()

    return result


if __name__ == "__main__":
    asyncio.run(main())
