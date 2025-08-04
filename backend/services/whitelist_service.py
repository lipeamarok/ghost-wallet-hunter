"""
Whitelist Service - Maintains known legitimate projects and addresses
Prevents false positives by identifying official tokens, exchanges, and verified projects
"""

import asyncio
import json
import logging
from typing import Set, Dict, List, Optional, Any
from datetime import datetime
import aiohttp
from aiohttp import ClientTimeout
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config.redis_config import redis_config

logger = logging.getLogger(__name__)


class WhitelistService:
    def __init__(self):
        self.redis_client = redis_config.get_client()
        self.legitimate_addresses: Set[str] = set()
        self.verified_tokens: Dict[str, Dict] = {}
        self.official_exchanges: Set[str] = set()
        self.last_update = None
        self.update_interval = 3600  # 1 hour

        # Initialize known legitimate addresses manually
        self._init_static_whitelist()

        # Whitelist sources
        self.sources = {
            'solana_token_list': {
                'url': 'https://raw.githubusercontent.com/solana-labs/token-list/main/src/tokens/solana.tokenlist.json',
                'parser': self._parse_solana_token_list
            },
            'coingecko_verified': {
                'url': 'https://api.coingecko.com/api/v3/coins/list?include_platform=true',
                'parser': self._parse_coingecko_verified
            }
        }

        # Log Redis status
        if redis_config.is_available():
            conn_info = redis_config.get_connection_info()
            logger.info(f"Whitelist using Redis: {conn_info['type']} ({conn_info['status']})")
        else:
            logger.warning("Whitelist running without Redis cache")

    def _init_static_whitelist(self):
        """Initialize manually curated whitelist of known legitimate addresses."""

        # Major tokens on Solana
        self.verified_tokens = {
            # Native SOL
            "So11111111111111111111111111111111111111112": {
                "name": "Wrapped SOL",
                "symbol": "SOL",
                "type": "native",
                "verified": True,
                "official": True
            },
            # USDC
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": {
                "name": "USD Coin",
                "symbol": "USDC",
                "type": "stablecoin",
                "verified": True,
                "official": True
            },
            # USDT
            "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB": {
                "name": "Tether USD",
                "symbol": "USDT",
                "type": "stablecoin",
                "verified": True,
                "official": True
            },
            # SAMO
            "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU": {
                "name": "Samoyedcoin",
                "symbol": "SAMO",
                "type": "memecoin",
                "verified": True,
                "official": True
            },
            # mSOL
            "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So": {
                "name": "Marinade staked SOL",
                "symbol": "mSOL",
                "type": "liquid_staking",
                "verified": True,
                "official": True
            },
            # RAY
            "4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R": {
                "name": "Raydium",
                "symbol": "RAY",
                "type": "defi",
                "verified": True,
                "official": True
            },
            # SRM
            "SRMuApVNdxXokk5GT7XD5cUUgXMBCoAz2LHeuAoKWRt": {
                "name": "Serum",
                "symbol": "SRM",
                "type": "defi",
                "verified": True,
                "official": True
            }
        }

        # Major exchanges and official programs
        self.official_exchanges = {
            # Raydium
            "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8",
            "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1",
            # Orca
            "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc",
            "9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP",
            # Jupiter
            "JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB",
            "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
            # Serum
            "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin",
            "EhqXDsotvYZGAzGJKS4t1JthyaS6U6mE2JNGNwFYkrn",
            # System programs
            "11111111111111111111111111111111",  # System Program
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",  # Token Program
        }

    async def check_address_legitimacy(self, address: str) -> Dict[str, Any]:
        """
        Check if an address is known to be legitimate.
        Returns comprehensive legitimacy information.
        """
        try:
            # Check cache first
            cached_result = await self._get_cached_legitimacy(address)
            if cached_result:
                return cached_result

            # Check static whitelist
            legitimacy_info = {
                "address": address,
                "is_legitimate": False,
                "confidence": 0.0,
                "sources": [],
                "token_info": None,
                "exchange_info": None,
                "verification_level": "unknown",
                "last_checked": datetime.now().isoformat()
            }

            # Check if it's a verified token
            if address in self.verified_tokens:
                token_info = self.verified_tokens[address]
                legitimacy_info.update({
                    "is_legitimate": True,
                    "confidence": 0.95,
                    "sources": ["static_whitelist", "verified_tokens"],
                    "token_info": token_info,
                    "verification_level": "official" if token_info.get("official") else "verified"
                })

            # Check if it's an official exchange/program
            elif address in self.official_exchanges:
                legitimacy_info.update({
                    "is_legitimate": True,
                    "confidence": 0.90,
                    "sources": ["static_whitelist", "official_exchanges"],
                    "exchange_info": {"type": "official_program"},
                    "verification_level": "official"
                })

            # If not in static lists, check dynamic sources
            else:
                await self._check_dynamic_sources(address, legitimacy_info)

            # Cache the result
            await self._cache_legitimacy_result(address, legitimacy_info)

            return legitimacy_info

        except Exception as e:
            logger.error(f" Error checking address legitimacy: {e}")
            return {
                "address": address,
                "is_legitimate": False,
                "confidence": 0.0,
                "sources": [],
                "error": str(e),
                "verification_level": "unknown",
                "last_checked": datetime.now().isoformat()
            }

    async def _check_dynamic_sources(self, address: str, legitimacy_info: Dict):
        """Check dynamic sources for address legitimacy."""

        # Check if we need to update from external sources
        if await self._should_update_whitelist():
            await self._update_from_sources()

        # Check against updated token list
        if address in self.verified_tokens:
            token_info = self.verified_tokens[address]
            legitimacy_info.update({
                "is_legitimate": True,
                "confidence": 0.85,
                "sources": legitimacy_info["sources"] + ["dynamic_token_list"],
                "token_info": token_info,
                "verification_level": "verified"
            })

    async def _should_update_whitelist(self) -> bool:
        """Check if whitelist needs updating."""
        if not self.last_update:
            return True

        time_since_update = datetime.now() - self.last_update
        return time_since_update.total_seconds() > self.update_interval

    async def _update_from_sources(self):
        """Update whitelist from external sources."""
        try:
            logger.info(" Updating whitelist from external sources...")

            for source_name, source_config in self.sources.items():
                try:
                    await self._fetch_and_parse_source(source_name, source_config)
                except Exception as e:
                    logger.warning(f" Failed to update from {source_name}: {e}")

            self.last_update = datetime.now()
            logger.info(f" Whitelist updated. Total verified tokens: {len(self.verified_tokens)}")

        except Exception as e:
            logger.error(f" Error updating whitelist: {e}")

    async def _fetch_and_parse_source(self, source_name: str, source_config: Dict):
        """Fetch and parse a specific whitelist source."""

        timeout = ClientTimeout(total=10)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.get(source_config['url']) as response:
                if response.status == 200:
                    data: Any = await response.json()
                    await source_config['parser'](data, source_name)
                else:
                    logger.warning(f" Failed to fetch {source_name}: HTTP {response.status}")

    async def _parse_solana_token_list(self, data: Dict, source_name: str):
        """Parse official Solana token list."""
        try:
            tokens = data.get('tokens', [])
            for token in tokens:
                address = token.get('address')
                if address and address not in self.verified_tokens:
                    self.verified_tokens[address] = {
                        "name": token.get('name', 'Unknown'),
                        "symbol": token.get('symbol', 'UNK'),
                        "type": "token",
                        "verified": True,
                        "official": True,
                        "source": source_name
                    }

            logger.info(f" Parsed {len(tokens)} tokens from {source_name}")

        except Exception as e:
            logger.error(f" Error parsing {source_name}: {e}")

    async def _parse_coingecko_verified(self, data: List, source_name: str):
        """Parse CoinGecko verified tokens."""
        try:
            solana_tokens = []
            for coin in data:
                platforms = coin.get('platforms', {})
                if 'solana' in platforms and platforms['solana']:
                    address = platforms['solana']
                    if address and address not in self.verified_tokens:
                        self.verified_tokens[address] = {
                            "name": coin.get('name', 'Unknown'),
                            "symbol": coin.get('symbol', 'UNK').upper(),
                            "type": "token",
                            "verified": True,
                            "official": False,
                            "source": source_name,
                            "coingecko_id": coin.get('id')
                        }
                        solana_tokens.append(address)

            logger.info(f" Parsed {len(solana_tokens)} Solana tokens from {source_name}")

        except Exception as e:
            logger.error(f" Error parsing {source_name}: {e}")

    async def _get_cached_legitimacy(self, address: str) -> Optional[Dict]:
        """Get cached legitimacy result."""
        if not self.redis_client:
            return None

        try:
            cached = self.redis_client.get(f"whitelist:{address}")
            if cached and isinstance(cached, (str, bytes)):
                return json.loads(cached)
        except Exception as e:
            logger.warning(f" Cache read error: {e}")

        return None

    async def _cache_legitimacy_result(self, address: str, result: Dict):
        """Cache legitimacy result."""
        if not self.redis_client:
            return

        try:
            # Cache for 1 hour
            self.redis_client.setex(
                f"whitelist:{address}",
                3600,
                json.dumps(result, default=str)
            )
        except Exception as e:
            logger.warning(f" Cache write error: {e}")

    async def is_legitimate_project(self, address: str) -> bool:
        """Simple boolean check for legitimacy."""
        result = await self.check_address_legitimacy(address)
        return result.get("is_legitimate", False)

    async def get_legitimacy_confidence(self, address: str) -> float:
        """Get confidence score for legitimacy (0.0 to 1.0)."""
        result = await self.check_address_legitimacy(address)
        return result.get("confidence", 0.0)

    def add_to_whitelist(self, address: str, info: Dict):
        """Manually add address to whitelist."""
        self.verified_tokens[address] = {
            **info,
            "verified": True,
            "source": "manual",
            "added_at": datetime.now().isoformat()
        }
        logger.info(f" Added {address} to whitelist manually")

    def remove_from_whitelist(self, address: str):
        """Remove address from whitelist."""
        if address in self.verified_tokens:
            del self.verified_tokens[address]
            logger.info(f" Removed {address} from whitelist")

    async def get_whitelist_stats(self) -> Dict:
        """Get whitelist statistics."""
        return {
            "total_verified_tokens": len(self.verified_tokens),
            "total_official_exchanges": len(self.official_exchanges),
            "last_update": self.last_update.isoformat() if self.last_update else None,
            "cache_enabled": self.redis_client is not None,
            "sources_configured": len(self.sources)
        }


# Global instance
whitelist_service = WhitelistService()
