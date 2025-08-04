"""
Solscan Integration Service
Provides verification of addresses through Solscan API to check if they are official/verified
"""

import asyncio
import json
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
import aiohttp
from aiohttp import ClientTimeout
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.redis_config import redis_config

logger = logging.getLogger(__name__)


class SolscanService:
    def __init__(self):
        self.base_url = "https://public-api.solscan.io"
        self.redis_client = redis_config.get_client()
        self.rate_limit = 100  # requests per minute
        self.request_count = 0
        self.last_reset = datetime.now()

        # Log Redis status
        if redis_config.is_available():
            conn_info = redis_config.get_connection_info()
            logger.info(f"Solscan using Redis: {conn_info['type']} ({conn_info['status']})")
        else:
            logger.warning("Solscan running without Redis cache")

    async def check_address_verification(self, address: str) -> Dict[str, Any]:
        """
        Check if an address is verified/official through Solscan.
        Returns comprehensive verification information.
        """
        try:
            # Check rate limit
            if not await self._check_rate_limit():
                logger.warning(" Solscan rate limit reached, using cached data only")
                cached_result = await self._get_cached_verification(address)
                if cached_result:
                    return cached_result
                else:
                    return self._create_error_result(address, "Rate limit reached")

            # Check cache first
            cached_result = await self._get_cached_verification(address)
            if cached_result:
                return cached_result

            verification_info = {
                "address": address,
                "is_verified": False,
                "is_official": False,
                "confidence": 0.0,
                "verification_sources": [],
                "token_info": None,
                "account_info": None,
                "error": None,
                "last_checked": datetime.now().isoformat()
            }

            # Check if it's a token
            token_info = await self._get_token_info(address)
            if token_info:
                verification_info["token_info"] = token_info
                verification_info["is_verified"] = token_info.get("verified", False)
                verification_info["confidence"] = 0.8 if token_info.get("verified") else 0.3
                verification_info["verification_sources"].append("solscan_token_registry")

            # Check account information
            account_info = await self._get_account_info(address)
            if account_info:
                verification_info["account_info"] = account_info

                # Check if it's a known program
                if account_info.get("executable", False):
                    verification_info["is_official"] = True
                    verification_info["confidence"] = max(verification_info["confidence"], 0.9)
                    verification_info["verification_sources"].append("solscan_program_registry")

            # Cache the result
            await self._cache_verification_result(address, verification_info)

            return verification_info

        except Exception as e:
            logger.error(f" Error checking Solscan verification for {address}: {e}")
            return self._create_error_result(address, str(e))

    async def _get_token_info(self, address: str) -> Optional[Dict]:
        """Get token information from Solscan."""
        try:
            url = f"{self.base_url}/token/meta"
            params = {"tokenAddress": address}

            timeout = ClientTimeout(total=10)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(url, params=params) as response:
                    if response.status == 200:
                        data: Dict = await response.json()

                        # Parse token metadata
                        return {
                            "name": data.get("name"),
                            "symbol": data.get("symbol"),
                            "decimals": data.get("decimals"),
                            "supply": data.get("supply"),
                            "verified": data.get("verified", False),
                            "icon": data.get("icon"),
                            "website": data.get("website"),
                            "description": data.get("description"),
                            "holders": data.get("holders"),
                            "market_cap": data.get("marketCap"),
                            "volume_24h": data.get("volume24h")
                        }
                    elif response.status == 404:
                        # Not a token, that's ok
                        return None
                    else:
                        logger.warning(f" Solscan token API error {response.status} for {address}")
                        return None

        except Exception as e:
            logger.warning(f" Error fetching token info from Solscan: {e}")
            return None

    async def _get_account_info(self, address: str) -> Optional[Dict]:
        """Get account information from Solscan."""
        try:
            url = f"{self.base_url}/account/{address}"

            timeout = ClientTimeout(total=10)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(url) as response:
                    if response.status == 200:
                        data: Dict = await response.json()

                        # Parse account data
                        return {
                            "lamports": data.get("lamports"),
                            "owner": data.get("owner"),
                            "executable": data.get("executable", False),
                            "rent_epoch": data.get("rentEpoch"),
                            "type": data.get("type"),
                            "program": data.get("program"),
                            "space": data.get("space")
                        }
                    elif response.status == 404:
                        # Account doesn't exist or not public
                        return None
                    else:
                        logger.warning(f" Solscan account API error {response.status} for {address}")
                        return None

        except Exception as e:
            logger.warning(f" Error fetching account info from Solscan: {e}")
            return None

    async def _check_rate_limit(self) -> bool:
        """Check if we're within rate limits."""
        now = datetime.now()

        # Reset counter every minute
        if (now - self.last_reset).total_seconds() >= 60:
            self.request_count = 0
            self.last_reset = now

        if self.request_count >= self.rate_limit:
            return False

        self.request_count += 1
        return True

    async def _get_cached_verification(self, address: str) -> Optional[Dict]:
        """Get cached verification result."""
        if not self.redis_client:
            return None

        try:
            cached = self.redis_client.get(f"solscan_verify:{address}")
            if cached and isinstance(cached, (str, bytes)):
                return json.loads(cached)
        except Exception as e:
            logger.warning(f" Cache read error: {e}")

        return None

    async def _cache_verification_result(self, address: str, result: Dict):
        """Cache verification result."""
        if not self.redis_client:
            return

        try:
            # Cache for 6 hours (verification status doesn't change often)
            self.redis_client.setex(
                f"solscan_verify:{address}",
                21600,
                json.dumps(result, default=str)
            )
        except Exception as e:
            logger.warning(f" Cache write error: {e}")

    def _create_error_result(self, address: str, error: str) -> Dict[str, Any]:
        """Create error result structure."""
        return {
            "address": address,
            "is_verified": False,
            "is_official": False,
            "confidence": 0.0,
            "verification_sources": [],
            "token_info": None,
            "account_info": None,
            "error": error,
            "last_checked": datetime.now().isoformat()
        }

    async def is_verified_token(self, address: str) -> bool:
        """Simple check if token is verified."""
        result = await self.check_address_verification(address)
        return result.get("is_verified", False)

    async def is_official_program(self, address: str) -> bool:
        """Simple check if address is an official program."""
        result = await self.check_address_verification(address)
        return result.get("is_official", False)

    async def get_verification_confidence(self, address: str) -> float:
        """Get verification confidence score (0.0 to 1.0)."""
        result = await self.check_address_verification(address)
        return result.get("confidence", 0.0)

    async def batch_check_verification(self, addresses: List[str]) -> Dict[str, Dict]:
        """Check verification for multiple addresses."""
        results = {}

        # Process in batches to respect rate limits
        batch_size = 10
        for i in range(0, len(addresses), batch_size):
            batch = addresses[i:i + batch_size]

            # Process batch concurrently
            tasks = [self.check_address_verification(addr) for addr in batch]
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)

            # Collect results
            for addr, result in zip(batch, batch_results):
                if isinstance(result, Exception):
                    results[addr] = self._create_error_result(addr, str(result))
                else:
                    results[addr] = result

            # Small delay between batches
            if i + batch_size < len(addresses):
                await asyncio.sleep(0.5)

        return results

    async def get_service_stats(self) -> Dict:
        """Get service statistics."""
        return {
            "base_url": self.base_url,
            "rate_limit": self.rate_limit,
            "requests_this_minute": self.request_count,
            "cache_enabled": self.redis_client is not None,
            "last_reset": self.last_reset.isoformat()
        }


# Global instance
solscan_service = SolscanService()
