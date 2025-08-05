#!/usr/bin/env python3
"""
Ghost Wallet Hunter A2A Setup
=============================

Script de configuração para integrar A2A com Ghost Wallet Hunter.
Cria agentes, configura servidor e testa a integração.
"""

import os
import sys
import asyncio
import subprocess
import time
from typing import List, Dict, Any


class GhostA2ASetup:
    """
    Configurador para integração A2A do Ghost Wallet Hunter
    """

    def __init__(self):
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        self.project_root = os.path.abspath(os.path.join(self.base_dir, "../../../"))
        self.core_dir = os.path.join(self.project_root, "core")
        self.a2a_dir = os.path.join(self.project_root, "a2a")

        self.julia_host = "http://127.0.0.1:8052/api/v1"
        self.a2a_port = 9100

        print(f"🏠 Project Root: {self.project_root}")
        print(f"🧠 Core Dir: {self.core_dir}")
        print(f"🔗 A2A Dir: {self.a2a_dir}")

    def check_prerequisites(self) -> bool:
        """
        Verifica se todos os pré-requisitos estão atendidos
        """
        print("\n🔍 Verificando pré-requisitos...")

        checks = []

        # Check Julia
        try:
            result = subprocess.run(["julia", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Julia: {result.stdout.strip()}")
                checks.append(True)
            else:
                print("❌ Julia não encontrado")
                checks.append(False)
        except FileNotFoundError:
            print("❌ Julia não instalado")
            checks.append(False)

        # Check Python
        try:
            version = sys.version.split()[0]
            print(f"✅ Python: {version}")
            checks.append(True)
        except:
            print("❌ Erro ao verificar Python")
            checks.append(False)

        # Check directories
        if os.path.exists(self.core_dir):
            print(f"✅ Core directory: {self.core_dir}")
            checks.append(True)
        else:
            print(f"❌ Core directory not found: {self.core_dir}")
            checks.append(False)

        if os.path.exists(self.a2a_dir):
            print(f"✅ A2A directory: {self.a2a_dir}")
            checks.append(True)
        else:
            print(f"❌ A2A directory not found: {self.a2a_dir}")
            checks.append(False)

        # Check Python dependencies
        required_packages = ["uvicorn", "starlette", "httpx"]
        for package in required_packages:
            try:
                __import__(package)
                print(f"✅ Python package: {package}")
                checks.append(True)
            except ImportError:
                print(f"❌ Python package missing: {package}")
                checks.append(False)

        success_rate = sum(checks) / len(checks)
        print(f"\n📊 Pré-requisitos: {success_rate:.1%} completos")

        return success_rate >= 0.8

    def install_python_dependencies(self):
        """
        Instala dependências Python necessárias
        """
        print("\n📦 Instalando dependências Python...")

        # Install basic dependencies
        basic_deps = [
            "uvicorn[standard]>=0.27.0",
            "starlette>=0.36.0",
            "httpx>=0.27.0",
            "python-dotenv>=1.0.0"
        ]

        for dep in basic_deps:
            print(f"Installing {dep}...")
            try:
                subprocess.run([sys.executable, "-m", "pip", "install", dep], check=True)
                print(f"✅ {dep} installed")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to install {dep}: {e}")

        # Try to install A2A SDK
        print("\nTentando instalar A2A SDK...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "a2a-sdk>=0.2.9"], check=True)
            print("✅ A2A SDK installed")
        except subprocess.CalledProcessError:
            print("⚠️ A2A SDK not available, will run in fallback mode")

        # Install JuliaOS Python wrapper
        juliaos_python_dir = os.path.join(self.project_root, "python")
        if os.path.exists(juliaos_python_dir):
            print(f"\nInstalando JuliaOS Python wrapper de {juliaos_python_dir}...")
            try:
                subprocess.run([sys.executable, "-m", "pip", "install", "-e", juliaos_python_dir], check=True)
                print("✅ JuliaOS Python wrapper installed")
            except subprocess.CalledProcessError as e:
                print(f"⚠️ JuliaOS Python wrapper installation failed: {e}")

    def setup_julia_server(self):
        """
        Configura e inicia servidor Julia (se não estiver rodando)
        """
        print(f"\n🖥️ Configurando servidor Julia...")

        # Check if Julia server is running
        try:
            import httpx
            import asyncio

            async def check_julia():
                try:
                    async with httpx.AsyncClient() as client:
                        response = await client.get(f"{self.julia_host}/health", timeout=2.0)
                        return response.status_code == 200
                except:
                    return False

            is_running = asyncio.run(check_julia())

            if is_running:
                print(f"✅ Servidor Julia já está rodando em {self.julia_host}")
                return True
            else:
                print(f"⚠️ Servidor Julia não está rodando em {self.julia_host}")
                print("Por favor, inicie o servidor Julia manualmente:")
                print(f"   cd {self.core_dir}")
                print("   julia run_server.jl")
                return False

        except ImportError:
            print("⚠️ httpx não disponível para verificar servidor Julia")
            return False

    def create_detective_agents(self):
        """
        Cria agentes detetives no JuliaOS
        """
        print("\n🕵️ Criando agentes detetives...")

        try:
            # Import JuliaOS
            sys.path.append(os.path.join(self.project_root, "python", "src"))
            import juliaos

            detective_configs = [
                ("poirot", "Hercule Poirot", "Methodical transaction analysis specialist"),
                ("marple", "Miss Jane Marple", "Anomaly detection expert"),
                ("spade", "Sam Spade", "Risk assessment specialist"),
                ("marlowe", "Philip Marlowe", "Bridge and mixer tracking expert"),
                ("dupin", "Auguste Dupin", "Compliance and AML analysis expert"),
                ("shadow", "The Shadow", "Network cluster analysis specialist"),
                ("raven", "Raven", "LLM explanation and communication expert")
            ]

            with juliaos.JuliaOSConnection(self.julia_host) as conn:
                print(f"🔗 Conectado ao JuliaOS: {self.julia_host}")

                existing_agents = conn.list_agents()
                existing_ids = [agent.id for agent in existing_agents]

                for detective_type, name, description in detective_configs:
                    agent_id = f"ghost_detective_{detective_type}"

                    if agent_id in existing_ids:
                        print(f"✅ Agente {name} já existe (ID: {agent_id})")
                        continue

                    try:
                        # Create agent blueprint
                        blueprint = juliaos.AgentBlueprint(
                            tools=[
                                juliaos.ToolBlueprint(
                                    name="analyze_wallet",
                                    config={"detective_type": detective_type}
                                ),
                                juliaos.ToolBlueprint(
                                    name="check_blacklist",
                                    config={"sources": ["solana_foundation"]}
                                )
                            ],
                            strategy=juliaos.StrategyBlueprint(
                                name="ghost_detective_strategy",
                                config={"type": detective_type}
                            ),
                            trigger=juliaos.TriggerConfig(
                                type="webhook",
                                params={"a2a_enabled": True}
                            )
                        )

                        # Create agent
                        agent = juliaos.Agent.create(conn, blueprint, agent_id, name, description)
                        agent.set_state(juliaos.AgentState.RUNNING)

                        print(f"✅ Agente {name} criado e iniciado (ID: {agent_id})")

                    except Exception as e:
                        print(f"❌ Erro ao criar agente {name}: {e}")

                print(f"\n📊 Agentes disponíveis: {len(conn.list_agents())}")

        except ImportError as e:
            print(f"❌ JuliaOS não disponível: {e}")
            print("Agentes serão criados em modo mock")
        except Exception as e:
            print(f"❌ Erro ao criar agentes: {e}")

    def start_a2a_server(self):
        """
        Inicia servidor A2A do Ghost Wallet Hunter
        """
        print(f"\n🚀 Iniciando servidor A2A na porta {self.a2a_port}...")

        server_script = os.path.join(self.a2a_dir, "src", "a2a", "ghost_server.py")

        if not os.path.exists(server_script):
            print(f"❌ Script do servidor não encontrado: {server_script}")
            return False

        try:
            print(f"Executando: python {server_script}")
            print(f"Servidor estará disponível em: http://127.0.0.1:{self.a2a_port}")
            print("Para parar o servidor, pressione Ctrl+C")
            print()

            # Change to A2A directory for proper imports
            os.chdir(os.path.join(self.a2a_dir, "src"))
            subprocess.run([sys.executable, "-m", "a2a.ghost_server"], check=True)

        except KeyboardInterrupt:
            print("\n🛑 Servidor A2A parado pelo usuário")
        except subprocess.CalledProcessError as e:
            print(f"❌ Erro ao executar servidor: {e}")
            return False
        except FileNotFoundError:
            print(f"❌ Arquivo servidor não encontrado")
            return False

        return True

    async def test_integration(self):
        """
        Testa a integração A2A
        """
        print("\n🧪 Testando integração A2A...")

        # Import client
        sys.path.append(os.path.join(self.a2a_dir, "src"))
        from a2a.ghost_client import GhostWalletHunterClient

        client = GhostWalletHunterClient(f"http://127.0.0.1:{self.a2a_port}")

        # Test health
        health = await client.check_server_health()
        if health.get("status") == "healthy":
            print("✅ Servidor A2A está saudável")
        else:
            print(f"❌ Problema com servidor A2A: {health}")
            return False

        # Test detective list
        detectives = await client.list_available_detectives()
        if "detectives" in detectives:
            print(f"✅ {detectives['total_detectives']} detetives disponíveis")
        else:
            print(f"❌ Erro ao listar detetives: {detectives}")
            return False

        # Test investigation
        test_wallet = "11111111111111111111111111111112"
        result = await client.investigate_with_detective("poirot", test_wallet)
        if "error" not in result:
            print("✅ Investigação teste bem-sucedida")
        else:
            print(f"❌ Erro na investigação teste: {result['error']}")
            return False

        print("🎯 Integração A2A testada com sucesso!")
        return True

    def run_full_setup(self):
        """
        Executa configuração completa
        """
        print("🔍 Ghost Wallet Hunter A2A Integration Setup")
        print("=" * 50)

        # 1. Check prerequisites
        if not self.check_prerequisites():
            print("\n❌ Pré-requisitos não atendidos. Por favor, resolva os problemas acima.")
            return False

        # 2. Install dependencies
        self.install_python_dependencies()

        # 3. Setup Julia server
        if not self.setup_julia_server():
            print("\n⚠️ Servidor Julia não está disponível. Continuando em modo mock...")

        # 4. Create detective agents
        self.create_detective_agents()

        # 5. Offer to start A2A server
        response = input("\n🚀 Deseja iniciar o servidor A2A agora? (y/N): ")
        if response.lower() in ['y', 'yes', 's', 'sim']:
            self.start_a2a_server()
        else:
            print(f"\n📋 Para iniciar o servidor A2A manualmente:")
            print(f"   cd {self.a2a_dir}/src")
            print(f"   python -m a2a.ghost_server")
            print(f"\n📋 Para testar a integração:")
            print(f"   cd {self.a2a_dir}/src")
            print(f"   python -m a2a.ghost_client")

        return True


def main():
    """
    Função principal
    """
    setup = GhostA2ASetup()

    if len(sys.argv) > 1:
        command = sys.argv[1].lower()

        if command == "check":
            setup.check_prerequisites()
        elif command == "install":
            setup.install_python_dependencies()
        elif command == "agents":
            setup.create_detective_agents()
        elif command == "server":
            setup.start_a2a_server()
        elif command == "test":
            asyncio.run(setup.test_integration())
        else:
            print(f"Comando desconhecido: {command}")
            print("Comandos disponíveis: check, install, agents, server, test")
    else:
        # Full setup
        setup.run_full_setup()


if __name__ == "__main__":
    main()
