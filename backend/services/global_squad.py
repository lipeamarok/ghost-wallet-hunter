"""
Global A2A Client Manager - Singleton Pattern

Manages a single global instance of the A2A client to avoid
repeated initialization on every API request.
"""

import logging
from typing import Optional

from services.ghost_a2a_client import GhostA2AClient

logger = logging.getLogger(__name__)

# Global instance
_global_a2a_client: Optional[GhostA2AClient] = None
_client_initialized = False


async def get_or_create_a2a_client():
    """Get the global A2A client instance, creating it if needed."""
    global _global_a2a_client, _client_initialized

    if _global_a2a_client is None or not _client_initialized:
        logger.info("🚨 Initializing global A2A client...")

        _global_a2a_client = GhostA2AClient()

        # A2A is always ready - no complex initialization needed
        _client_initialized = True
        logger.info("✅ Global A2A client ready!")

    return _global_a2a_client


def is_a2a_ready() -> bool:
    """Check if the global A2A client is ready."""
    return _client_initialized


def get_a2a_instance():
    """Get the A2A client instance (may be None if not initialized)."""
    return _global_a2a_client
