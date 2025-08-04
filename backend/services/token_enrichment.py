"""
Token Enrichment Service

Provides token recognition and contextual information for Ghost Wallet Hunter.
Integrates with external APIs to identify tokens, protocols, and contexts.
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional, Union
from datetime import datetime, timedelta
import httpx
import json
from functools import lru_cache

logger = logging.getLogger(__name__)


class TokenType:
    """Token type classifications."""
    MEMECOIN = "memecoin"
    DEFI_TOKEN = "defi_token"
    NFT_COLLECTION = "nft_collection"
    STABLECOIN = "stablecoin"
    EXCHANGE_TOKEN = "exchange_token"
    GOVERNANCE_TOKEN = "governance_token"
    UTILITY_TOKEN = "utility_token"
    UNKNOWN = "unknown"


class WalletContext:
    """Wallet context classifications."""
    EXCHANGE_WALLET = "exchange_wallet"
    PROTOCOL_TREASURY = "protocol_treasury"
    MEMECOIN_TRADER = "memecoin_trader"
    DEFI_USER = "defi_user"
    NFT_COLLECTOR = "nft_collector"
    BOT_WALLET = "bot_wallet"
    NORMAL_USER = "normal_user"
    UNKNOWN = "unknown"


class TokenEnrichmentService:
    """Service for enriching token and wallet data with contextual information."""

    def __init__(self):
        """Initialize token enrichment service."""
        self.client = httpx.AsyncClient(timeout=30.0)
        self.cache_duration = timedelta(hours=1)
        self._token_cache = {}
        self._wallet_cache = {}

        # Known protocol addresses and patterns
        self.known_protocols = {
            # DEX Programs
            "JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4": "Jupiter",
            "srmqPiDukx7YOL8sSogZhqY6vBPFKAT4GKNP9j4b9Es": "Serum",
            "9KEPoZmtHUrBbhWN1v1KWLMkkvwY6WLtAVUCPRTnRMUe": "Raydium",

            # Lending/Borrowing
            "M2mx93ekt1fmXSVkTrUL9xVFHkmME8HTUi5Cyc5aF7K": "Mango",
            "So1endDq2YkqhipRh3WViPa8hdiSpxWy6z3Z6tMCpAo": "Solend",

            # Stablecoins
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": "USDC",
            "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB": "USDT",

            # Popular tokens
            "So11111111111111111111111111111111111111112": "Wrapped SOL (WSOL)",
            "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So": "Marinade SOL (mSOL)",
        }

        # Known exchange wallet patterns
        self.exchange_patterns = {
            "Binance", "Coinbase", "FTX", "OKX", "KuCoin", "Gate.io", "Huobi"
        }

    async def enrich_token_info(self, token_address: str) -> Dict[str, Any]:
        """
        Enrich token information with external data sources.

        Args:
            token_address: Token mint address

        Returns:
            Dict with enriched token information
        """
        try:
            # Check cache first
            if token_address in self._token_cache:
                cached = self._token_cache[token_address]
                if datetime.now() - cached['timestamp'] < self.cache_duration:
                    return cached['data']

            # Check known protocols first
            if token_address in self.known_protocols:
                token_info = {
                    "address": token_address,
                    "name": self.known_protocols[token_address],
                    "symbol": self.known_protocols[token_address].upper()[:10],
                    "type": TokenType.DEFI_TOKEN,
                    "description": f"Known protocol: {self.known_protocols[token_address]}",
                    "confidence": 1.0,
                    "source": "internal_db"
                }
            else:
                # Try to fetch from external APIs
                token_info = await self._fetch_token_from_apis(token_address)

            # Cache the result
            self._token_cache[token_address] = {
                'data': token_info,
                'timestamp': datetime.now()
            }

            return token_info

        except Exception as e:
            logger.error(f"Failed to enrich token info for {token_address}: {e}")
            return {
                "address": token_address,
                "name": "Unknown Token",
                "symbol": "UNKNOWN",
                "type": TokenType.UNKNOWN,
                "confidence": 0.0,
                "error": str(e)
            }

    async def _fetch_token_from_apis(self, token_address: str) -> Dict[str, Any]:
        """Fetch token information from external APIs."""
        token_info = {
            "address": token_address,
            "name": "Unknown Token",
            "symbol": "UNKNOWN",
            "type": TokenType.UNKNOWN,
            "confidence": 0.0
        }

        # Try Jupiter API first (most comprehensive for Solana)
        try:
            jupiter_data = await self._fetch_from_jupiter(token_address)
            if jupiter_data:
                token_info.update(jupiter_data)
                token_info["source"] = "jupiter"
                return token_info
        except Exception as e:
            logger.debug(f"Jupiter API failed for {token_address}: {e}")

        # Try CoinGecko as fallback
        try:
            coingecko_data = await self._fetch_from_coingecko(token_address)
            if coingecko_data:
                token_info.update(coingecko_data)
                token_info["source"] = "coingecko"
                return token_info
        except Exception as e:
            logger.debug(f"CoinGecko API failed for {token_address}: {e}")

        # Try Solscan as another fallback
        try:
            solscan_data = await self._fetch_from_solscan(token_address)
            if solscan_data:
                token_info.update(solscan_data)
                token_info["source"] = "solscan"
                return token_info
        except Exception as e:
            logger.debug(f"Solscan API failed for {token_address}: {e}")

        return token_info

    async def _fetch_from_jupiter(self, token_address: str) -> Optional[Dict[str, Any]]:
        """Fetch token data from Jupiter API."""
        try:
            url = f"https://token.jup.ag/token/{token_address}"
            response = await self.client.get(url)

            if response.status_code == 200:
                data = response.json()
                return {
                    "name": data.get("name", "Unknown"),
                    "symbol": data.get("symbol", "UNKNOWN"),
                    "decimals": data.get("decimals", 9),
                    "type": self._classify_token_type(data),
                    "confidence": 0.9,
                    "logo_uri": data.get("logoURI"),
                    "tags": data.get("tags", [])
                }
        except Exception as e:
            logger.debug(f"Jupiter API error: {e}")

        return None

    async def _fetch_from_coingecko(self, token_address: str) -> Optional[Dict[str, Any]]:
        """Fetch token data from CoinGecko API."""
        try:
            # CoinGecko API for Solana tokens
            url = f"https://api.coingecko.com/api/v3/coins/solana/contract/{token_address}"
            response = await self.client.get(url)

            if response.status_code == 200:
                data = response.json()
                return {
                    "name": data.get("name", "Unknown"),
                    "symbol": data.get("symbol", "UNKNOWN").upper(),
                    "market_cap": data.get("market_data", {}).get("market_cap", {}).get("usd"),
                    "price_usd": data.get("market_data", {}).get("current_price", {}).get("usd"),
                    "type": self._classify_token_type(data),
                    "confidence": 0.8,
                    "coingecko_id": data.get("id"),
                    "description": data.get("description", {}).get("en", "")[:200]
                }
        except Exception as e:
            logger.debug(f"CoinGecko API error: {e}")

        return None

    async def _fetch_from_solscan(self, token_address: str) -> Optional[Dict[str, Any]]:
        """Fetch token data from Solscan API."""
        try:
            url = f"https://public-api.solscan.io/token/meta?tokenAddress={token_address}"
            response = await self.client.get(url)

            if response.status_code == 200:
                data = response.json()
                return {
                    "name": data.get("name", "Unknown"),
                    "symbol": data.get("symbol", "UNKNOWN"),
                    "decimals": data.get("decimals", 9),
                    "type": self._classify_token_type(data),
                    "confidence": 0.7,
                    "supply": data.get("supply"),
                    "holder_count": data.get("holder")
                }
        except Exception as e:
            logger.debug(f"Solscan API error: {e}")

        return None

    def _classify_token_type(self, token_data: Dict[str, Any]) -> str:
        """Classify token type based on available data."""
        name = token_data.get("name", "").lower()
        symbol = token_data.get("symbol", "").lower()
        tags = token_data.get("tags", [])

        # Check for stablecoins
        if any(stable in name for stable in ["usd", "usdc", "usdt", "dai", "busd"]):
            return TokenType.STABLECOIN

        # Check for governance tokens
        if any(gov in name for gov in ["gov", "governance"]) or "governance" in tags:
            return TokenType.GOVERNANCE_TOKEN

        # Check for memecoins (common patterns)
        memecoin_indicators = ["doge", "shib", "pepe", "bonk", "meme", "inu", "moon", "rocket"]
        if any(meme in name for meme in memecoin_indicators):
            return TokenType.MEMECOIN

        # Check market cap for memecoin classification
        market_cap = token_data.get("market_cap")
        if market_cap and market_cap < 1000000:  # < 1M market cap
            return TokenType.MEMECOIN

        # Default classification
        return TokenType.UTILITY_TOKEN

    async def analyze_wallet_context(self, wallet_address: str, transactions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analyze wallet context based on transaction patterns.

        Args:
            wallet_address: Wallet address to analyze
            transactions: List of wallet transactions

        Returns:
            Dict with wallet context analysis
        """
        try:
            # Check cache first
            cache_key = f"{wallet_address}_{len(transactions)}"
            if cache_key in self._wallet_cache:
                cached = self._wallet_cache[cache_key]
                if datetime.now() - cached['timestamp'] < self.cache_duration:
                    return cached['data']

            context_analysis = {
                "wallet_address": wallet_address,
                "context_type": WalletContext.UNKNOWN,
                "confidence": 0.0,
                "characteristics": [],
                "token_interactions": {},
                "protocol_usage": [],
                "risk_indicators": [],
                "trading_patterns": {}
            }

            if not transactions:
                return context_analysis

            # Analyze transaction patterns
            await self._analyze_transaction_patterns(context_analysis, transactions)

            # Analyze token interactions
            await self._analyze_token_interactions(context_analysis, transactions)

            # Analyze protocol usage
            await self._analyze_protocol_usage(context_analysis, transactions)

            # Determine final context classification
            context_analysis["context_type"] = self._determine_wallet_context(context_analysis)

            # Cache the result
            self._wallet_cache[cache_key] = {
                'data': context_analysis,
                'timestamp': datetime.now()
            }

            return context_analysis

        except Exception as e:
            logger.error(f"Failed to analyze wallet context for {wallet_address}: {e}")
            return {
                "wallet_address": wallet_address,
                "context_type": WalletContext.UNKNOWN,
                "confidence": 0.0,
                "error": str(e)
            }

    async def _analyze_transaction_patterns(self, analysis: Dict[str, Any], transactions: List[Dict[str, Any]]):
        """Analyze transaction patterns for context clues."""
        if not transactions:
            return

        # Calculate transaction frequency
        tx_count = len(transactions)
        time_span = self._calculate_time_span(transactions)

        if time_span > 0:
            daily_tx_rate = tx_count / (time_span / 86400)  # transactions per day

            if daily_tx_rate > 100:
                analysis["characteristics"].append("high_frequency_trading")
                analysis["risk_indicators"].append("potential_bot_activity")
            elif daily_tx_rate > 10:
                analysis["characteristics"].append("active_trader")

        # Analyze transaction sizes and patterns
        amounts = [self._extract_amount(tx) for tx in transactions]
        amounts = [amt for amt in amounts if amt > 0]

        if amounts:
            avg_amount = sum(amounts) / len(amounts)
            if avg_amount > 1000:  # Large transactions
                analysis["characteristics"].append("whale_activity")

            # Check for round number patterns (bot indicator)
            round_numbers = sum(1 for amt in amounts if amt == round(amt))
            if round_numbers / len(amounts) > 0.8:
                analysis["characteristics"].append("round_number_pattern")
                analysis["risk_indicators"].append("potential_automated_trading")

    async def _analyze_token_interactions(self, analysis: Dict[str, Any], transactions: List[Dict[str, Any]]):
        """Analyze which tokens the wallet interacts with."""
        token_counts = {}
        unique_tokens = set()

        for tx in transactions:
            # Extract token addresses from transaction
            tokens = self._extract_tokens_from_tx(tx)
            for token in tokens:
                token_counts[token] = token_counts.get(token, 0) + 1
                unique_tokens.add(token)

        analysis["token_interactions"] = {
            "unique_tokens": len(unique_tokens),
            "most_traded": dict(sorted(token_counts.items(), key=lambda x: x[1], reverse=True)[:10])
        }

        # Classify based on token diversity
        if len(unique_tokens) > 50:
            analysis["characteristics"].append("diversified_portfolio")
        elif len(unique_tokens) < 5:
            analysis["characteristics"].append("focused_trading")

    async def _analyze_protocol_usage(self, analysis: Dict[str, Any], transactions: List[Dict[str, Any]]):
        """Analyze which protocols the wallet uses."""
        protocol_usage = {}

        for tx in transactions:
            programs = self._extract_programs_from_tx(tx)
            for program in programs:
                if program in self.known_protocols:
                    protocol_name = self.known_protocols[program]
                    protocol_usage[protocol_name] = protocol_usage.get(protocol_name, 0) + 1

        analysis["protocol_usage"] = list(protocol_usage.keys())

        # Classify based on protocol usage
        if "Jupiter" in protocol_usage or "Raydium" in protocol_usage:
            analysis["characteristics"].append("dex_user")
        if "Mango" in protocol_usage or "Solend" in protocol_usage:
            analysis["characteristics"].append("defi_user")

    def _determine_wallet_context(self, analysis: Dict[str, Any]) -> str:
        """Determine the primary wallet context based on analysis."""
        characteristics = analysis["characteristics"]

        # Priority-based classification
        if "high_frequency_trading" in characteristics:
            analysis["confidence"] = 0.8
            return WalletContext.BOT_WALLET

        if "defi_user" in characteristics:
            analysis["confidence"] = 0.7
            return WalletContext.DEFI_USER

        if "dex_user" in characteristics and "active_trader" in characteristics:
            analysis["confidence"] = 0.6
            return WalletContext.MEMECOIN_TRADER

        if "whale_activity" in characteristics:
            analysis["confidence"] = 0.5
            return WalletContext.EXCHANGE_WALLET

        analysis["confidence"] = 0.3
        return WalletContext.NORMAL_USER

    def _calculate_time_span(self, transactions: List[Dict[str, Any]]) -> float:
        """Calculate time span of transactions in seconds."""
        timestamps = []
        for tx in transactions:
            if "blockTime" in tx and tx["blockTime"]:
                timestamps.append(tx["blockTime"])

        if len(timestamps) < 2:
            return 0

        return max(timestamps) - min(timestamps)

    def _extract_amount(self, transaction: Dict[str, Any]) -> float:
        """Extract transaction amount from transaction data."""
        try:
            meta = transaction.get("meta", {})
            pre_balances = meta.get("preBalances", [])
            post_balances = meta.get("postBalances", [])

            if pre_balances and post_balances:
                balance_change = abs(pre_balances[0] - post_balances[0])
                return balance_change / 1_000_000_000  # Convert lamports to SOL
        except:
            pass

        return 0.0

    def _extract_tokens_from_tx(self, transaction: Dict[str, Any]) -> List[str]:
        """Extract token addresses from transaction."""
        tokens = []
        try:
            account_keys = transaction.get("transaction", {}).get("message", {}).get("accountKeys", [])
            # Filter out system accounts and focus on potential token accounts
            for key in account_keys:
                if len(key) == 44:  # Solana address length
                    tokens.append(key)
        except:
            pass

        return tokens

    def _extract_programs_from_tx(self, transaction: Dict[str, Any]) -> List[str]:
        """Extract program IDs from transaction."""
        programs = []
        try:
            instructions = transaction.get("transaction", {}).get("message", {}).get("instructions", [])
            for instruction in instructions:
                program_id = instruction.get("programId")
                if program_id:
                    programs.append(program_id)
        except:
            pass

        return programs

    async def generate_contextual_prompt(self, wallet_address: str, token_info: Dict[str, Any],
                                       wallet_context: Dict[str, Any]) -> str:
        """
        Generate an enriched prompt with contextual information for AI analysis.

        Args:
            wallet_address: Wallet being analyzed
            token_info: Enriched token information
            wallet_context: Wallet context analysis

        Returns:
            Enhanced prompt with contextual information
        """
        prompt_parts = [
            f"WALLET ANALYSIS FOR: {wallet_address}",
            "",
            "=== TOKEN CONTEXT ==="
        ]

        if token_info.get("name") != "Unknown Token":
            prompt_parts.extend([
                f"Token Name: {token_info.get('name')}",
                f"Symbol: {token_info.get('symbol')}",
                f"Type: {token_info.get('type')}",
                f"Source: {token_info.get('source', 'unknown')}"
            ])

            if token_info.get("description"):
                prompt_parts.append(f"Description: {token_info.get('description')}")

            if token_info.get("market_cap"):
                prompt_parts.append(f"Market Cap: ${token_info.get('market_cap'):,.2f}")
        else:
            prompt_parts.append("Token: Unknown/Unidentified token")

        prompt_parts.extend([
            "",
            "=== WALLET CONTEXT ===",
            f"Wallet Type: {wallet_context.get('context_type')}",
            f"Confidence: {wallet_context.get('confidence', 0):.1%}"
        ])

        if wallet_context.get("characteristics"):
            prompt_parts.append(f"Characteristics: {', '.join(wallet_context.get('characteristics', []))}")

        if wallet_context.get("protocol_usage"):
            prompt_parts.append(f"Used Protocols: {', '.join(wallet_context.get('protocol_usage', []))}")

        if wallet_context.get("risk_indicators"):
            prompt_parts.append(f"Risk Indicators: {', '.join(wallet_context.get('risk_indicators', []))}")

        prompt_parts.extend([
            "",
            "=== ANALYSIS INSTRUCTIONS ===",
            "Please provide a comprehensive analysis that includes:",
            "1. Token identification and context (if applicable)",
            "2. Wallet behavior classification",
            "3. Risk assessment based on patterns",
            "4. Specific insights about this wallet type",
            "5. Any notable characteristics or red flags",
            "",
            "Be specific about what you can identify vs. what appears suspicious."
        ])

        return "\n".join(prompt_parts)

    async def close(self):
        """Close the HTTP client."""
        if self.client:
            await self.client.aclose()


# Global service instance
_token_enrichment_service = None


async def get_token_enrichment_service() -> TokenEnrichmentService:
    """Get or create the global token enrichment service instance."""
    global _token_enrichment_service
    if _token_enrichment_service is None:
        _token_enrichment_service = TokenEnrichmentService()
    return _token_enrichment_service
