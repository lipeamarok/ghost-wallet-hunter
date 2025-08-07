#!/usr/bin/env python3
"""
Ghost Wallet Hunter Backend Server Starter
Inicia o servidor backend com integração JuliaOS ativa.
"""

import sys
import os
import subprocess
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def start_server():
    """Start Ghost Wallet Hunter backend server"""
    try:
        logger.info("🚀 Starting Ghost Wallet Hunter Backend Server...")
        logger.info("🔗 JuliaOS Integration: Enabled (port 10000)")
        logger.info("🕵️‍♂️ Detective Squad: Phase 4 Active")
        logger.info("🧠 Swarm Intelligence: Coordinated Analysis")
        logger.info("📡 Backend Server: Starting on port 8001...")

        # Get the project root directory
        project_root = Path(__file__).parent.parent
        venv_python = project_root / ".venv" / "Scripts" / "python.exe"

        # Check if virtual environment exists
        if venv_python.exists():
            logger.info(f"✅ Using virtual environment: {venv_python}")
            python_cmd = str(venv_python)
        else:
            logger.warning("⚠️ Virtual environment not found, using system Python")
            python_cmd = sys.executable

        # Start FastAPI server with virtual environment Python
        cmd = [
            python_cmd, "-m", "uvicorn",
            "main:app",
            "--host", "0.0.0.0",
            "--port", "8001",
            "--reload",
            "--timeout-keep-alive", "30",
            "--timeout-graceful-shutdown", "30"
        ]

        logger.info(f"🔧 Running command: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)

    except KeyboardInterrupt:
        logger.info("👋 Shutting down Ghost Wallet Hunter Backend...")
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Failed to start server: {e}")
        logger.info("💡 Try: pip install uvicorn fastapi")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    start_server()
