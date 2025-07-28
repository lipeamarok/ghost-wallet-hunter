"""
Global Squad Manager - Singleton Pattern

Manages a single global instance of the Detective Squad to avoid
repeated initialization on every API request.
"""

import logging
from typing import Optional, TYPE_CHECKING

if TYPE_CHECKING:
    from agents.detective_squad import DetectiveSquadManager

logger = logging.getLogger(__name__)

# Global instance
_global_squad: Optional['DetectiveSquadManager'] = None
_squad_initialized = False


async def get_or_create_squad():
    """Get the global squad instance, creating it if needed."""
    global _global_squad, _squad_initialized

    if _global_squad is None or not _squad_initialized:
        logger.info("🚨 Initializing global detective squad...")

        from agents.detective_squad import DetectiveSquadManager
        _global_squad = DetectiveSquadManager()

        # Initialize the squad
        if _global_squad:
            _squad_initialized = await _global_squad.initialize_squad()

        if _squad_initialized:
            logger.info("✅ Global detective squad ready!")
        else:
            logger.warning("⚠️ Global detective squad partially initialized")

    return _global_squad


def is_squad_ready() -> bool:
    """Check if the global squad is ready."""
    return _squad_initialized


def get_squad_instance():
    """Get the squad instance (may be None if not initialized)."""
    return _global_squad
