# 🚀 GHOST WALLET HUNTER - JULIA SERVICE SIMPLES
# Sem burocracia, só funcionalidade!

import aiohttp
import asyncio
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class SimpleJuliaService:
    """Serviço Julia SIMPLES - sem complicação!"""
    
    def __init__(self, port: int = 8053):
        self.url = f"http://localhost:{port}"
        self.session = None
        self.connected = False
    
    async def initialize(self):
        """Conectar com servidor Julia"""
        try:
            self.session = aiohttp.ClientSession()
            
            async with self.session.get(f"{self.url}/health") as response:
                if response.status == 200:
                    data = await response.json()
                    self.connected = True
                    
                    logger.info("🚀 Julia server connected!")
                    logger.info(f"📊 Julia version: {data.get('julia_version')}")
                    logger.info(f"🕵️ Detectives: {data.get('detectives_count')}")
                    logger.info(f"⚡ Performance: {data.get('performance')}")
                    return True
                    
        except Exception as e:
            logger.warning(f"❌ Julia server not available: {e}")
            self.connected = False
            return False
    
    async def investigate_wallet(self, wallet_address: str) -> Dict[str, Any]:
        """Investigar carteira com Julia power!"""
        if not self.connected:
            return {"error": "Julia server not connected"}
        
        try:
            payload = {"wallet_address": wallet_address}
            
            async with self.session.post(
                f"{self.url}/investigate",
                json=payload
            ) as response:
                
                if response.status == 200:
                    result = await response.json()
                    logger.info(f"✅ Julia investigation completed in {result.get('investigation_time_ms')}ms")
                    return result
                else:
                    return {"error": f"Investigation failed: {response.status}"}
                    
        except Exception as e:
            logger.error(f"Investigation error: {e}")
            return {"error": str(e)}
    
    async def get_detectives(self) -> Dict[str, Any]:
        """Listar detetives disponíveis"""
        if not self.connected:
            return {"error": "Julia server not connected"}
        
        try:
            async with self.session.get(f"{self.url}/detectives") as response:
                if response.status == 200:
                    return await response.json()
                else:
                    return {"error": f"Failed to get detectives: {response.status}"}
                    
        except Exception as e:
            return {"error": str(e)}
    
    async def close(self):
        """Fechar conexão"""
        if self.session:
            await self.session.close()

# 🎯 INSTÂNCIA GLOBAL SIMPLES
julia_service = SimpleJuliaService()

# 🔧 FUNÇÕES DE CONVENIÊNCIA
async def initialize_julia():
    return await julia_service.initialize()

async def investigate_with_julia(wallet_address: str):
    return await julia_service.investigate_wallet(wallet_address)

async def get_julia_detectives():
    return await julia_service.get_detectives()
