"""
AI Cost Tracking Service

Service for tracking AI usage costs across all detectives and providers.
Provides real-time monitoring, budget controls, and analytics.
"""

import asyncio
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import json
from pathlib import Path

logger = logging.getLogger(__name__)


@dataclass
class CostRecord:
    """Individual cost record for AI API call."""
    timestamp: datetime
    user_id: str
    detective: str
    provider: str
    model: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    cost: float
    analysis_type: str
    success: bool
    response_time: float


@dataclass
class UsageStatistics:
    """Usage statistics for a user or period."""
    user_id: str
    period_start: datetime
    period_end: datetime
    total_calls: int = 0
    successful_calls: int = 0
    failed_calls: int = 0
    total_cost: float = 0.0
    total_tokens: int = 0
    avg_response_time: float = 0.0
    detective_breakdown: Dict[str, Dict] = field(default_factory=dict)
    provider_breakdown: Dict[str, Dict] = field(default_factory=dict)


@dataclass
class BudgetLimits:
    """Budget and rate limits for a user."""
    user_id: str
    daily_cost_limit: float = 10.0
    monthly_cost_limit: float = 100.0
    calls_per_minute: int = 10
    calls_per_hour: int = 100
    calls_per_day: int = 500
    auto_stop_on_limit: bool = True
    alert_thresholds: List[float] = field(default_factory=lambda: [0.5, 0.8, 0.95])


class AICostTracker:
    """AI Cost Tracking and Management Service."""

    def __init__(self, data_dir: str = "data/ai_costs"):
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)

        # In-memory storage for fast access
        self.cost_records: List[CostRecord] = []
        self.user_limits: Dict[str, BudgetLimits] = {}
        self.daily_usage: Dict[str, Dict] = {}  # user_id -> daily stats
        self.minute_calls: Dict[str, List] = {}  # user_id -> list of timestamps

        # Load existing data
        self._load_data()

    def _load_data(self):
        """Load existing cost data and limits."""
        try:
            # Load cost records from today
            today = datetime.now().date()
            cost_file = self.data_dir / f"costs_{today.isoformat()}.json"

            if cost_file.exists():
                with open(cost_file, 'r') as f:
                    records_data = json.load(f)
                    for record_data in records_data:
                        record = CostRecord(
                            timestamp=datetime.fromisoformat(record_data['timestamp']),
                            **{k: v for k, v in record_data.items() if k != 'timestamp'}
                        )
                        self.cost_records.append(record)

            # Load user limits
            limits_file = self.data_dir / "user_limits.json"
            if limits_file.exists():
                with open(limits_file, 'r') as f:
                    limits_data = json.load(f)
                    for user_id, limits in limits_data.items():
                        self.user_limits[user_id] = BudgetLimits(user_id=user_id, **limits)

        except Exception as e:
            logger.error(f"Error loading cost data: {e}")

    def _save_data(self):
        """Save current cost data and limits."""
        try:
            # Save today's cost records
            today = datetime.now().date()
            cost_file = self.data_dir / f"costs_{today.isoformat()}.json"

            today_records = [r for r in self.cost_records if r.timestamp.date() == today]
            records_data = []

            for record in today_records:
                records_data.append({
                    'timestamp': record.timestamp.isoformat(),
                    'user_id': record.user_id,
                    'detective': record.detective,
                    'provider': record.provider,
                    'model': record.model,
                    'prompt_tokens': record.prompt_tokens,
                    'completion_tokens': record.completion_tokens,
                    'total_tokens': record.total_tokens,
                    'cost': record.cost,
                    'analysis_type': record.analysis_type,
                    'success': record.success,
                    'response_time': record.response_time
                })

            with open(cost_file, 'w') as f:
                json.dump(records_data, f, indent=2)

            # Save user limits
            limits_file = self.data_dir / "user_limits.json"
            limits_data = {}
            for user_id, limits in self.user_limits.items():
                limits_data[user_id] = {
                    'daily_cost_limit': limits.daily_cost_limit,
                    'monthly_cost_limit': limits.monthly_cost_limit,
                    'calls_per_minute': limits.calls_per_minute,
                    'calls_per_hour': limits.calls_per_hour,
                    'calls_per_day': limits.calls_per_day,
                    'auto_stop_on_limit': limits.auto_stop_on_limit,
                    'alert_thresholds': limits.alert_thresholds
                }

            with open(limits_file, 'w') as f:
                json.dump(limits_data, f, indent=2)

        except Exception as e:
            logger.error(f"Error saving cost data: {e}")

    async def record_api_call(
        self,
        user_id: str,
        detective: str,
        provider: str,
        model: str,
        prompt_tokens: int,
        completion_tokens: int,
        cost: float,
        analysis_type: str,
        success: bool,
        response_time: float
    ) -> bool:
        """Record an AI API call for cost tracking."""
        try:
            record = CostRecord(
                timestamp=datetime.now(),
                user_id=user_id,
                detective=detective,
                provider=provider,
                model=model,
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=prompt_tokens + completion_tokens,
                cost=cost,
                analysis_type=analysis_type,
                success=success,
                response_time=response_time
            )

            self.cost_records.append(record)

            # Update daily usage
            self._update_daily_usage(user_id, record)

            # Update minute calls for rate limiting
            self._update_minute_calls(user_id)

            # Save data periodically
            if len(self.cost_records) % 10 == 0:
                self._save_data()

            return True

        except Exception as e:
            logger.error(f"Error recording API call: {e}")
            return False

    def _update_daily_usage(self, user_id: str, record: CostRecord):
        """Update daily usage statistics."""
        today = datetime.now().date().isoformat()

        if user_id not in self.daily_usage:
            self.daily_usage[user_id] = {}

        if today not in self.daily_usage[user_id]:
            self.daily_usage[user_id][today] = {
                'calls': 0,
                'cost': 0.0,
                'tokens': 0,
                'detectives': {},
                'providers': {}
            }

        daily = self.daily_usage[user_id][today]
        daily['calls'] += 1
        daily['cost'] += record.cost
        daily['tokens'] += record.total_tokens

        # Detective breakdown
        if record.detective not in daily['detectives']:
            daily['detectives'][record.detective] = {'calls': 0, 'cost': 0.0}
        daily['detectives'][record.detective]['calls'] += 1
        daily['detectives'][record.detective]['cost'] += record.cost

        # Provider breakdown
        if record.provider not in daily['providers']:
            daily['providers'][record.provider] = {'calls': 0, 'cost': 0.0}
        daily['providers'][record.provider]['calls'] += 1
        daily['providers'][record.provider]['cost'] += record.cost

    def _update_minute_calls(self, user_id: str):
        """Update minute call tracking for rate limiting."""
        now = datetime.now()

        if user_id not in self.minute_calls:
            self.minute_calls[user_id] = []

        # Add current call
        self.minute_calls[user_id].append(now)

        # Remove calls older than 1 minute
        cutoff = now - timedelta(minutes=1)
        self.minute_calls[user_id] = [
            call_time for call_time in self.minute_calls[user_id]
            if call_time > cutoff
        ]

    async def check_rate_limits(self, user_id: str) -> Dict[str, Any]:
        """Check if user is within rate limits."""
        limits = self.get_user_limits(user_id)
        now = datetime.now()

        # Minute check
        minute_calls = len(self.minute_calls.get(user_id, []))
        minute_ok = minute_calls < limits.calls_per_minute

        # Hour check
        hour_ago = now - timedelta(hours=1)
        hour_calls = len([
            r for r in self.cost_records
            if r.user_id == user_id and r.timestamp > hour_ago
        ])
        hour_ok = hour_calls < limits.calls_per_hour

        # Day check
        today = now.date()
        day_calls = len([
            r for r in self.cost_records
            if r.user_id == user_id and r.timestamp.date() == today
        ])
        day_ok = day_calls < limits.calls_per_day

        # Cost checks
        today_cost = sum([
            r.cost for r in self.cost_records
            if r.user_id == user_id and r.timestamp.date() == today
        ])
        daily_cost_ok = today_cost < limits.daily_cost_limit

        return {
            "within_limits": minute_ok and hour_ok and day_ok and daily_cost_ok,
            "limits_status": {
                "minute": {"allowed": minute_ok, "current": minute_calls, "limit": limits.calls_per_minute},
                "hour": {"allowed": hour_ok, "current": hour_calls, "limit": limits.calls_per_hour},
                "day": {"allowed": day_ok, "current": day_calls, "limit": limits.calls_per_day},
                "daily_cost": {"allowed": daily_cost_ok, "current": today_cost, "limit": limits.daily_cost_limit}
            }
        }

    def get_user_limits(self, user_id: str) -> BudgetLimits:
        """Get budget limits for a user."""
        if user_id not in self.user_limits:
            self.user_limits[user_id] = BudgetLimits(user_id=user_id)
        return self.user_limits[user_id]

    async def update_user_limits(self, user_id: str, **kwargs) -> bool:
        """Update budget limits for a user."""
        try:
            limits = self.get_user_limits(user_id)

            for key, value in kwargs.items():
                if hasattr(limits, key):
                    setattr(limits, key, value)

            self._save_data()
            return True

        except Exception as e:
            logger.error(f"Error updating user limits: {e}")
            return False

    async def get_usage_statistics(self, user_id: str, days: int = 7) -> UsageStatistics:
        """Get usage statistics for a user over specified days."""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)

        relevant_records = [
            r for r in self.cost_records
            if r.user_id == user_id and start_date <= r.timestamp <= end_date
        ]

        stats = UsageStatistics(
            user_id=user_id,
            period_start=start_date,
            period_end=end_date
        )

        if not relevant_records:
            return stats

        stats.total_calls = len(relevant_records)
        stats.successful_calls = len([r for r in relevant_records if r.success])
        stats.failed_calls = stats.total_calls - stats.successful_calls
        stats.total_cost = sum(r.cost for r in relevant_records)
        stats.total_tokens = sum(r.total_tokens for r in relevant_records)
        stats.avg_response_time = sum(r.response_time for r in relevant_records) / len(relevant_records)

        # Detective breakdown
        for record in relevant_records:
            if record.detective not in stats.detective_breakdown:
                stats.detective_breakdown[record.detective] = {'calls': 0, 'cost': 0.0, 'tokens': 0}
            stats.detective_breakdown[record.detective]['calls'] += 1
            stats.detective_breakdown[record.detective]['cost'] += record.cost
            stats.detective_breakdown[record.detective]['tokens'] += record.total_tokens

        # Provider breakdown
        for record in relevant_records:
            if record.provider not in stats.provider_breakdown:
                stats.provider_breakdown[record.provider] = {'calls': 0, 'cost': 0.0, 'tokens': 0}
            stats.provider_breakdown[record.provider]['calls'] += 1
            stats.provider_breakdown[record.provider]['cost'] += record.cost
            stats.provider_breakdown[record.provider]['tokens'] += record.total_tokens

        return stats

    async def get_dashboard_data(self) -> Dict[str, Any]:
        """Get comprehensive dashboard data."""
        now = datetime.now()
        today = now.date()

        # Overall statistics
        total_records = len(self.cost_records)
        today_records = [r for r in self.cost_records if r.timestamp.date() == today]

        total_cost_today = sum(r.cost for r in today_records)
        total_calls_today = len(today_records)
        successful_calls_today = len([r for r in today_records if r.success])

        # Detective breakdown
        detective_stats = {}
        for record in today_records:
            if record.detective not in detective_stats:
                detective_stats[record.detective] = {'calls': 0, 'cost': 0.0}
            detective_stats[record.detective]['calls'] += 1
            detective_stats[record.detective]['cost'] += record.cost

        # Provider breakdown
        provider_stats = {}
        for record in today_records:
            if record.provider not in provider_stats:
                provider_stats[record.provider] = {'calls': 0, 'cost': 0.0}
            provider_stats[record.provider]['calls'] += 1
            provider_stats[record.provider]['cost'] += record.cost

        # Active users
        active_users = len(set(r.user_id for r in today_records))

        return {
            "timestamp": now.isoformat(),
            "overview": {
                "total_cost_today": round(total_cost_today, 4),
                "total_calls_today": total_calls_today,
                "successful_calls_today": successful_calls_today,
                "success_rate": (successful_calls_today / total_calls_today * 100) if total_calls_today > 0 else 0,
                "active_users_today": active_users,
                "total_records_all_time": total_records
            },
            "detective_breakdown": detective_stats,
            "provider_breakdown": provider_stats,
            "health": {
                "service_status": "operational",
                "data_directory": str(self.data_dir),
                "records_in_memory": len(self.cost_records),
                "users_tracked": len(self.user_limits)
            }
        }


# Global cost tracker instance
cost_tracker = AICostTracker()


async def record_ai_cost(
    user_id: str,
    detective: str,
    provider: str,
    model: str,
    prompt_tokens: int,
    completion_tokens: int,
    cost: float,
    analysis_type: str,
    success: bool,
    response_time: float
) -> bool:
    """Convenience function to record AI cost."""
    return await cost_tracker.record_api_call(
        user_id, detective, provider, model,
        prompt_tokens, completion_tokens, cost,
        analysis_type, success, response_time
    )


async def check_user_limits(user_id: str) -> Dict[str, Any]:
    """Convenience function to check user limits."""
    return await cost_tracker.check_rate_limits(user_id)


async def get_cost_dashboard() -> Dict[str, Any]:
    """Convenience function to get cost dashboard."""
    return await cost_tracker.get_dashboard_data()
