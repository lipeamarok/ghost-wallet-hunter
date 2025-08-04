"""
Blacklist Checker Service
Integrates with multiple sources to check wallet addresses against known scam/malicious addresses
"""

import asyncio
import json
import logging
import time
from typing import Set, Dict, List, Optional
from datetime import datetime, timedelta
import aiohttp
from aiohttp import ClientTimeout

logger = logging.getLogger(__name__)

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    logger.warning("Redis not installed, running without cache")

class BlacklistChecker:
    def __init__(self):
        self.redis_client = None
        self.scam_addresses: Set[str] = set()
        self.last_update = None
        self.update_interval = 300  # 5 minutes

        # Blacklist sources
        self.sources = {
            'solana_foundation': {
                'url': 'https://raw.githubusercontent.com/solana-labs/token-list/main/src/scam-list.json',
                'parser': self._parse_solana_foundation
            },
            'chainabuse_solana': {
                'url': 'https://raw.githubusercontent.com/cryptoscamdb/blacklist/master/data/solana.json',
                'parser': self._parse_chainabuse
            }
        }

        # Try to initialize Redis if available
        if REDIS_AVAILABLE:
            try:
                self.redis_client = redis.Redis(
                    host='localhost',
                    port=6379,
                    decode_responses=True,
                    socket_connect_timeout=1,
                    socket_timeout=1
                )
                # Test connection
                self.redis_client.ping()
                logger.info("Redis connection established")
            except Exception as e:
                logger.warning(f"Redis not available: {str(e)}. Running without cache.")
                self.redis_client = None
        else:
            logger.info("Redis not installed, running without cache")

    async def initialize(self):
        """Initialize the blacklist checker with latest data"""
        logger.info("Initializing blacklist checker...")
        await self.update_blacklists()
        logger.info(f"Blacklist initialized with {len(self.scam_addresses)} addresses")

    async def update_blacklists(self) -> bool:
        """Update blacklists from all sources"""
        try:
            all_addresses = set()

            async with aiohttp.ClientSession() as session:
                tasks = []
                for source_name, source_config in self.sources.items():
                    task = self._fetch_source(session, source_name, source_config)
                    tasks.append(task)

                results = await asyncio.gather(*tasks, return_exceptions=True)

                for result in results:
                    if isinstance(result, Exception):
                        logger.error(f"Error fetching blacklist: {result}")
                        continue
                    if result and isinstance(result, set):
                        all_addresses.update(result)

            if all_addresses:
                self.scam_addresses = all_addresses
                self.last_update = datetime.now()

                # Cache in Redis if available
                if self.redis_client:
                    try:
                        self.redis_client.setex(
                            'blacklist:addresses',
                            86400,  # 24 hours
                            json.dumps(list(all_addresses))
                        )
                        self.redis_client.setex(
                            'blacklist:last_update',
                            86400,
                            self.last_update.isoformat()
                        )
                    except Exception as e:
                        logger.error(f"Redis cache error: {e}")

                logger.info(f"Updated blacklist with {len(all_addresses)} addresses")
                return True

        except Exception as e:
            logger.error(f"Failed to update blacklists: {e}")

        return False

    async def _fetch_source(self, session: aiohttp.ClientSession, source_name: str, source_config: dict) -> Set[str]:
        """Fetch addresses from a specific source"""
        try:
            logger.info(f"Fetching {source_name}...")

            timeout = ClientTimeout(total=30)
            async with session.get(source_config['url'], timeout=timeout) as response:
                if response.status == 200:
                    data = await response.json()
                    addresses = source_config['parser'](data)
                    logger.info(f"{source_name}: {len(addresses)} addresses")
                    return addresses
                else:
                    logger.warning(f"{source_name}: HTTP {response.status}")

        except Exception as e:
            logger.error(f"Error fetching {source_name}: {e}")

        return set()

    def _parse_solana_foundation(self, data: dict) -> Set[str]:
        """Parse Solana Foundation scam list format"""
        addresses = set()
        try:
            # Check different possible structures
            if 'tags' in data and 'scam' in data['tags']:
                for entry in data['tags']['scam']:
                    if 'address' in entry:
                        addresses.add(entry['address'])

            # Alternative format - direct list
            elif isinstance(data, list):
                for entry in data:
                    if isinstance(entry, dict) and 'address' in entry:
                        addresses.add(entry['address'])
                    elif isinstance(entry, str):
                        addresses.add(entry)

        except Exception as e:
            logger.error(f"Error parsing Solana Foundation data: {e}")

        return addresses

    def _parse_chainabuse(self, data: dict) -> Set[str]:
        """Parse Chainabuse format"""
        addresses = set()
        try:
            if isinstance(data, list):
                for entry in data:
                    if isinstance(entry, dict):
                        addr = entry.get('address') or entry.get('wallet') or entry.get('account')
                        if addr:
                            addresses.add(addr)
                    elif isinstance(entry, str):
                        addresses.add(entry)

        except Exception as e:
            logger.error(f"Error parsing Chainabuse data: {e}")

        return addresses

    async def check_address(self, address: str) -> Dict:
        """Check if an address is blacklisted"""
        # Auto-update if needed
        if self._should_update():
            await self.update_blacklists()

        is_blacklisted = address in self.scam_addresses

        result = {
            'address': address,
            'is_blacklisted': is_blacklisted,
            'threat_level': 'HIGH' if is_blacklisted else 'CLEAN',
            'last_checked': datetime.now().isoformat(),
            'sources_checked': list(self.sources.keys())
        }

        if is_blacklisted:
            result['warning'] = f"ALERTA: Endereço {address[:8]}...{address[-8:]} está listado em bases públicas de scam/golpes!"
            result['recommendation'] = "Recomendamos cautela máxima. Evite transações com este endereço."

        return result

    async def check_multiple_addresses(self, addresses: List[str]) -> Dict:
        """Check multiple addresses against blacklist"""
        results = []
        blacklisted_count = 0

        for address in addresses:
            check_result = await self.check_address(address)
            results.append(check_result)
            if check_result['is_blacklisted']:
                blacklisted_count += 1

        return {
            'addresses_checked': len(addresses),
            'blacklisted_found': blacklisted_count,
            'threat_level': 'HIGH' if blacklisted_count > 0 else 'CLEAN',
            'results': results,
            'summary': f"{blacklisted_count} de {len(addresses)} endereços estão em listas de scam" if blacklisted_count > 0
                      else f"Nenhum dos {len(addresses)} endereços verificados está em listas de scam"
        }

    def _should_update(self) -> bool:
        """Check if blacklist should be updated"""
        if not self.last_update:
            return True
        return datetime.now() - self.last_update > timedelta(seconds=self.update_interval)

    async def get_stats(self) -> Dict:
        """Get blacklist statistics"""
        return {
            'total_addresses': len(self.scam_addresses),
            'last_update': self.last_update.isoformat() if self.last_update else None,
            'sources_active': len(self.sources),
            'cache_available': self.redis_client is not None,
            'update_interval_minutes': self.update_interval // 60
        }

# Global instance
blacklist_checker = BlacklistChecker()

async def initialize_blacklist():
    """Initialize the global blacklist checker"""
    await blacklist_checker.initialize()

async def check_wallet_blacklist(address: str) -> Dict:
    """Public interface to check a wallet address"""
    return await blacklist_checker.check_address(address)

async def check_wallets_blacklist(addresses: List[str]) -> Dict:
    """Public interface to check multiple wallet addresses"""
    return await blacklist_checker.check_multiple_addresses(addresses)
