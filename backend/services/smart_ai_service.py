"""
AI Configuration Service

Advanced AI configuration system for Ghost Wallet Hunter.
Supports multiple AI providers with cost control, rate limiting, and temperature settings.
"""

from enum import Enum
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import asyncio
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

# Import cost tracking (async import to avoid circular dependencies)
try:
    from services.cost_tracking import record_ai_cost, check_user_limits
    COST_TRACKING_AVAILABLE = True
except ImportError:
    COST_TRACKING_AVAILABLE = False
    logger.warning("Cost tracking not available - continuing without cost tracking")


class AIProvider(Enum):
    """Supported AI providers."""
    OPENAI = "openai"
    GROK = "grok"
    JULIAOS = "juliaos"
    MOCK = "mock"  # For development/testing


class AIModel(Enum):
    """AI models available for each provider."""
    # OpenAI Models
    GPT_4_TURBO = "gpt-4-turbo-preview"
    GPT_4 = "gpt-4"
    GPT_3_5_TURBO = "gpt-3.5-turbo"

    # Grok Models
    GROK_BETA = "grok-beta"

    # JuliaOS Models
    JULIAOS_DEFAULT = "juliaos-default"

    # Mock for testing
    MOCK_MODEL = "mock-model"


class AIConfiguration(BaseModel):
    """AI configuration settings."""

    # Provider Selection - REAL AI BY DEFAULT! 🚀
    primary_provider: AIProvider = AIProvider.OPENAI
    fallback_providers: List[AIProvider] = [AIProvider.GROK, AIProvider.MOCK]

    # Model Selection per Provider
    models: Dict[AIProvider, AIModel] = {
        AIProvider.OPENAI: AIModel.GPT_3_5_TURBO,
        AIProvider.GROK: AIModel.GROK_BETA,
        AIProvider.JULIAOS: AIModel.JULIAOS_DEFAULT,
        AIProvider.MOCK: AIModel.MOCK_MODEL
    }

    # Temperature & Generation Settings
    temperature: float = 0.7  # 0.0 = deterministic, 1.0 = creative
    max_tokens: int = 1000
    top_p: float = 0.9
    frequency_penalty: float = 0.0
    presence_penalty: float = 0.0

    # Cost Control
    max_cost_per_request: float = 0.05  # USD
    max_cost_per_user_daily: float = 1.00  # USD per user per day
    max_cost_per_user_monthly: float = 10.00  # USD per user per month
    max_total_daily_cost: float = 50.00  # USD total daily limit

    # Rate Limiting
    requests_per_minute_per_user: int = 10
    requests_per_hour_per_user: int = 100
    requests_per_day_per_user: int = 500

    # Quality Control
    min_confidence_threshold: float = 0.6
    enable_content_filtering: bool = True
    log_all_requests: bool = True

    # Retry & Fallback
    max_retries: int = 3
    retry_delay_seconds: float = 1.0
    enable_fallback: bool = True


class UserUsageTracker:
    """Track AI usage per user for cost and rate limiting."""

    def __init__(self):
        self.usage_data: Dict[str, Dict] = {}
        self.cost_data: Dict[str, Dict] = {}

    def get_user_stats(self, user_id: str) -> Dict[str, Any]:
        """Get current usage stats for a user."""
        now = datetime.now()
        today = now.date()
        current_hour = now.replace(minute=0, second=0, microsecond=0)
        current_minute = now.replace(second=0, microsecond=0)

        if user_id not in self.usage_data:
            return {
                "requests_this_minute": 0,
                "requests_this_hour": 0,
                "requests_today": 0,
                "cost_today": 0.0,
                "cost_this_month": 0.0
            }

        user_data = self.usage_data[user_id]
        cost_data = self.cost_data.get(user_id, {})

        return {
            "requests_this_minute": user_data.get(str(current_minute), 0),
            "requests_this_hour": user_data.get(str(current_hour), 0),
            "requests_today": sum(
                count for time_key, count in user_data.items()
                if time_key.startswith(str(today))
            ),
            "cost_today": sum(
                cost for time_key, cost in cost_data.items()
                if time_key.startswith(str(today))
            ),
            "cost_this_month": sum(
                cost for time_key, cost in cost_data.items()
                if time_key.startswith(f"{today.year}-{today.month:02d}")
            )
        }

    def can_make_request(self, user_id: str, config: AIConfiguration) -> tuple[bool, str]:
        """Check if user can make an AI request based on limits."""
        stats = self.get_user_stats(user_id)

        # Check rate limits
        if stats["requests_this_minute"] >= config.requests_per_minute_per_user:
            return False, "Rate limit exceeded: too many requests per minute"

        if stats["requests_this_hour"] >= config.requests_per_hour_per_user:
            return False, "Rate limit exceeded: too many requests per hour"

        if stats["requests_today"] >= config.requests_per_day_per_user:
            return False, "Rate limit exceeded: daily request limit reached"

        # Check cost limits
        if stats["cost_today"] >= config.max_cost_per_user_daily:
            return False, "Cost limit exceeded: daily spending limit reached"

        if stats["cost_this_month"] >= config.max_cost_per_user_monthly:
            return False, "Cost limit exceeded: monthly spending limit reached"

        return True, "OK"

    def record_usage(self, user_id: str, cost: float = 0.0):
        """Record a usage event for a user."""
        now = datetime.now()
        current_minute = now.replace(second=0, microsecond=0)
        current_hour = now.replace(minute=0, second=0, microsecond=0)
        today = now.date()

        # Initialize user data if needed
        if user_id not in self.usage_data:
            self.usage_data[user_id] = {}
            self.cost_data[user_id] = {}

        # Record request count
        minute_key = str(current_minute)
        hour_key = str(current_hour)
        day_key = str(today)

        self.usage_data[user_id][minute_key] = self.usage_data[user_id].get(minute_key, 0) + 1
        self.usage_data[user_id][hour_key] = self.usage_data[user_id].get(hour_key, 0) + 1
        self.usage_data[user_id][day_key] = self.usage_data[user_id].get(day_key, 0) + 1

        # Record cost
        if cost > 0:
            self.cost_data[user_id][day_key] = self.cost_data[user_id].get(day_key, 0.0) + cost


class SmartAIService:
    """Smart AI service with provider switching, cost control, and rate limiting."""

    def __init__(self, config: AIConfiguration):
        self.config = config
        self.usage_tracker = UserUsageTracker()
        self.daily_cost = 0.0
        self.daily_cost_date = datetime.now().date()

    async def analyze_with_ai(
        self,
        prompt: str,
        user_id: str = "anonymous",
        context: Optional[Dict] = None,
        analysis_type: str = "general"
    ) -> Dict[str, Any]:
        """
        Perform AI analysis with intelligent provider selection and cost control.

        Args:
            prompt: The analysis prompt
            user_id: User identifier for rate limiting
            context: Additional context for the AI
            analysis_type: Type of analysis for specialized handling

        Returns:
            AI analysis result with metadata
        """

        # Check if user can make request
        can_request, reason = self.usage_tracker.can_make_request(user_id, self.config)
        if not can_request:
            logger.warning(f"AI request blocked for user {user_id}: {reason}")
            return {
                "error": "Request limit exceeded",
                "reason": reason,
                "fallback_analysis": self._get_fallback_analysis(analysis_type)
            }

        # Check daily cost limit
        if self._check_daily_cost_limit():
            logger.warning("Daily cost limit reached, using fallback analysis")
            return {
                "error": "Daily cost limit reached",
                "fallback_analysis": self._get_fallback_analysis(analysis_type)
            }

        # Try primary provider first, then fallbacks
        providers_to_try = [self.config.primary_provider] + self.config.fallback_providers

        for provider in providers_to_try:
            try:
                start_time = datetime.now()
                result = await self._call_ai_provider(provider, prompt, context, analysis_type)
                response_time = (datetime.now() - start_time).total_seconds()

                # Estimate and record cost
                estimated_cost = self._estimate_cost(provider, prompt, result)
                self.usage_tracker.record_usage(user_id, estimated_cost)
                self._update_daily_cost(estimated_cost)

                # Record cost tracking if available
                if COST_TRACKING_AVAILABLE:
                    try:
                        # Extract token counts from result or estimate
                        prompt_tokens = len(prompt.split()) * 1.3  # Rough estimation
                        completion_tokens = len(str(result.get('analysis', '')).split()) * 1.3

                        await record_ai_cost(
                            user_id=user_id,
                            detective=context.get('detective', 'unknown') if context else 'unknown',
                            provider=provider.value,
                            model=self.config.models[provider].value,
                            prompt_tokens=int(prompt_tokens),
                            completion_tokens=int(completion_tokens),
                            cost=estimated_cost,
                            analysis_type=analysis_type,
                            success=True,
                            response_time=response_time
                        )
                    except Exception as cost_error:
                        logger.warning(f"Cost tracking failed: {cost_error}")

                # Add metadata
                result.update({
                    "provider_used": provider.value,
                    "estimated_cost": estimated_cost,
                    "user_id": user_id,
                    "timestamp": datetime.now().isoformat(),
                    "config": {
                        "temperature": self.config.temperature,
                        "model": self.config.models[provider].value
                    }
                })

                logger.info(f"AI analysis completed using {provider.value} for user {user_id}")
                return result

            except Exception as e:
                logger.error(f"AI provider {provider.value} failed: {e}")
                continue

        # All providers failed, return fallback
        logger.error("All AI providers failed, using fallback analysis")
        return {
            "error": "All AI providers unavailable",
            "fallback_analysis": self._get_fallback_analysis(analysis_type)
        }

    def _check_daily_cost_limit(self) -> bool:
        """Check if daily cost limit has been reached."""
        today = datetime.now().date()
        if self.daily_cost_date != today:
            self.daily_cost = 0.0
            self.daily_cost_date = today

        return self.daily_cost >= self.config.max_total_daily_cost

    def _update_daily_cost(self, cost: float):
        """Update daily cost tracking."""
        today = datetime.now().date()
        if self.daily_cost_date != today:
            self.daily_cost = 0.0
            self.daily_cost_date = today

        self.daily_cost += cost

    async def _call_ai_provider(
        self,
        provider: AIProvider,
        prompt: str,
        context: Optional[Dict],
        analysis_type: str
    ) -> Dict[str, Any]:
        """Call specific AI provider."""

        if provider == AIProvider.MOCK:
            return await self._call_mock_ai(prompt, context, analysis_type)
        elif provider == AIProvider.OPENAI:
            return await self._call_openai(prompt, context, analysis_type)
        elif provider == AIProvider.GROK:
            return await self._call_grok(prompt, context, analysis_type)
        elif provider == AIProvider.JULIAOS:
            return await self._call_juliaos(prompt, context, analysis_type)
        else:
            raise ValueError(f"Unsupported provider: {provider}")

    async def _call_mock_ai(self, prompt: str, context: Optional[Dict], analysis_type: str) -> Dict[str, Any]:
        """Mock AI implementation with realistic responses."""
        await asyncio.sleep(0.2)  # Simulate API delay

        # Sophisticated mock responses based on analysis type and prompt content
        if analysis_type == "transaction_analysis" or "transaction" in prompt.lower():
            return {
                "analysis": "Advanced transaction pattern analysis reveals clustering behavior",
                "risk_score": 0.65,
                "patterns": ["round_amounts", "timing_correlation", "frequent_micro_transactions"],
                "confidence": 0.82,
                "reasoning": "Multiple indicators suggest coordinated wallet activity including synchronized transactions and round-number transfers typical of money laundering schemes."
            }

        elif analysis_type == "compliance" or "compliance" in prompt.lower():
            return {
                "compliance_status": "requires_enhanced_monitoring",
                "aml_risk": "medium",
                "sanctions_check": "clear",
                "regulatory_flags": ["frequent_small_amounts", "cross_border_activity"],
                "confidence": 0.88,
                "recommendations": ["implement_kyc_verification", "monitor_transaction_velocity"]
            }

        else:
            return {
                "analysis": "Comprehensive AI analysis completed",
                "insights": "Wallet shows moderate risk profile with some suspicious indicators",
                "confidence": 0.75,
                "key_findings": ["transaction_clustering", "behavioral_anomalies"]
            }

    async def _call_openai(self, prompt: str, context: Optional[Dict], analysis_type: str) -> Dict[str, Any]:
        """OpenAI API implementation with real API calls."""
        from openai import AsyncOpenAI
        from config.settings import get_settings

        settings = get_settings()
        if not settings.OPENAI_API_KEY:
            raise ValueError("OpenAI API key not configured")

        client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

        # Build system prompt based on analysis type
        system_prompt = self._build_system_prompt(analysis_type)

        # Build user prompt with context
        user_prompt = self._build_user_prompt(prompt, context, analysis_type)

        try:
            response = await client.chat.completions.create(
                model=self.config.models[AIProvider.OPENAI].value,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=self.config.temperature,
                max_tokens=self.config.max_tokens,
                top_p=self.config.top_p,
                frequency_penalty=self.config.frequency_penalty,
                presence_penalty=self.config.presence_penalty
            )

            # Parse AI response into structured format
            ai_content = response.choices[0].message.content or ""
            result = self._parse_ai_response(ai_content, analysis_type)

            # Add token usage info
            if response.usage:
                result["token_usage"] = {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                }

            return result

        except Exception as e:
            logger.error(f"OpenAI API call failed: {e}")
            raise

    def _build_system_prompt(self, analysis_type: str) -> str:
        """Build system prompt based on analysis type."""
        base_prompt = """You are an expert blockchain analyst specializing in cryptocurrency fraud detection and wallet analysis.
You analyze transaction patterns, identify suspicious activities, and provide detailed risk assessments.
Always respond with structured JSON containing your analysis results."""

        if analysis_type == "transaction_analysis":
            return base_prompt + """

Focus on:
- Transaction clustering patterns
- Money laundering indicators
- Volume anomalies
- Timing correlations
- Address behavior patterns

Provide: risk_score (0-1), patterns array, confidence (0-1), reasoning string."""

        elif analysis_type == "compliance":
            return base_prompt + """

Focus on:
- AML compliance assessment
- Sanctions screening
- Regulatory risk factors
- KYC requirements
- Compliance status determination

Provide: compliance_status, aml_risk, sanctions_check, regulatory_flags array, confidence, recommendations array."""

        else:
            return base_prompt + """

Provide comprehensive wallet analysis including risk assessment, behavioral patterns, and actionable insights.
Format as JSON with analysis, insights, confidence, and key_findings."""

    def _build_user_prompt(self, prompt: str, context: Optional[Dict], analysis_type: str) -> str:
        """Build user prompt with context."""
        user_prompt = f"Analysis Request: {prompt}\n\n"

        if context:
            user_prompt += f"Context Data: {context}\n\n"

        user_prompt += f"Analysis Type: {analysis_type}\n\n"
        user_prompt += "Please provide your analysis in valid JSON format."

        return user_prompt

    def _parse_ai_response(self, ai_content: str, analysis_type: str) -> Dict[str, Any]:
        """Parse AI response into structured format."""
        import json
        import re

        try:
            # Try to extract JSON from the response
            json_match = re.search(r'\{.*\}', ai_content, re.DOTALL)
            if json_match:
                json_str = json_match.group()
                return json.loads(json_str)
            else:
                # If no JSON found, create structured response
                return {
                    "analysis": ai_content,
                    "confidence": 0.8,
                    "method": "ai_generated",
                    "raw_response": ai_content
                }
        except json.JSONDecodeError:
            # Fallback to text analysis
            return {
                "analysis": ai_content,
                "confidence": 0.7,
                "method": "ai_text_analysis",
                "raw_response": ai_content
            }

    async def _call_grok(self, prompt: str, context: Optional[Dict], analysis_type: str) -> Dict[str, Any]:
        """Grok/X.AI API implementation with real API calls."""
        import httpx
        from config.settings import get_settings

        settings = get_settings()
        if not settings.GROK_API_KEY:
            raise ValueError("Grok API key not configured")

        # Build prompts
        system_prompt = self._build_system_prompt(analysis_type)
        user_prompt = self._build_user_prompt(prompt, context, analysis_type)

        # Grok API endpoint
        url = "https://api.x.ai/v1/chat/completions"

        headers = {
            "Authorization": f"Bearer {settings.GROK_API_KEY}",
            "Content-Type": "application/json"
        }

        payload = {
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "model": self.config.models[AIProvider.GROK].value,
            "temperature": self.config.temperature,
            "max_tokens": self.config.max_tokens,
            "top_p": self.config.top_p
        }

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(url, json=payload, headers=headers)
                response.raise_for_status()

                data = response.json()

                # Parse AI response
                ai_content = data["choices"][0]["message"]["content"] or ""
                result = self._parse_ai_response(ai_content, analysis_type)

                # Add usage info if available
                if "usage" in data:
                    result["token_usage"] = data["usage"]

                return result

        except Exception as e:
            logger.error(f"Grok API call failed: {e}")
            raise

    async def _call_juliaos(self, prompt: str, context: Optional[Dict], analysis_type: str) -> Dict[str, Any]:
        """JuliaOS API implementation."""
        # JuliaOS integration ready for future implementation
        return await self._call_mock_ai(prompt, context, analysis_type)

    def _estimate_cost(self, provider: AIProvider, prompt: str, result: Dict[str, Any]) -> float:
        """Estimate cost of AI request."""
        # Rough cost estimation based on token usage
        prompt_tokens = len(prompt.split()) * 1.3  # Rough estimation
        response_tokens = len(str(result)) / 4  # Rough estimation

        if provider == AIProvider.OPENAI:
            # GPT-3.5-turbo pricing (approximate)
            return (prompt_tokens * 0.0015 + response_tokens * 0.002) / 1000
        elif provider == AIProvider.GROK:
            # Grok pricing (estimated)
            return (prompt_tokens + response_tokens) * 0.001 / 1000
        elif provider == AIProvider.JULIAOS:
            # JuliaOS pricing (estimated)
            return (prompt_tokens + response_tokens) * 0.0005 / 1000
        else:
            return 0.0  # Mock is free

    def _get_fallback_analysis(self, analysis_type: str) -> Dict[str, Any]:
        """Provide fallback analysis when AI is unavailable."""
        return {
            "analysis": f"Fallback {analysis_type} analysis using rule-based system",
            "confidence": 0.6,
            "method": "rule_based_fallback",
            "note": "AI analysis temporarily unavailable"
        }

    def get_usage_stats(self, user_id: str) -> Dict[str, Any]:
        """Get usage statistics for a user."""
        return self.usage_tracker.get_user_stats(user_id)

    def get_system_stats(self) -> Dict[str, Any]:
        """Get system-wide AI usage statistics."""
        return {
            "daily_cost": self.daily_cost,
            "daily_cost_limit": self.config.max_total_daily_cost,
            "cost_utilization": (self.daily_cost / self.config.max_total_daily_cost) * 100,
            "active_provider": self.config.primary_provider.value,
            "fallback_providers": [p.value for p in self.config.fallback_providers]
        }


# Global AI service instance
_ai_service: Optional[SmartAIService] = None

def get_ai_service() -> SmartAIService:
    """Get global AI service instance."""
    global _ai_service
    if _ai_service is None:
        config = AIConfiguration()
        _ai_service = SmartAIService(config)
    return _ai_service

def configure_ai_service(config: AIConfiguration) -> SmartAIService:
    """Configure AI service with custom settings."""
    global _ai_service
    _ai_service = SmartAIService(config)
    return _ai_service
