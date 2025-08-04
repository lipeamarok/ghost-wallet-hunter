"""
Redis Configuration Serv            logger.warning("Redis not available, caching disabled")ce
Handles Redis connection based on environment variables (production/development)
"""

import os
import logging
from typing import Optional
from urllib.parse import urlparse

logger = logging.getLogger(__name__)

try:
    import redis
    from redis import Redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    logger.warning("Redis not installed, running without cache")


class RedisConfig:
    def __init__(self):
        self.redis_client: Optional[Redis] = None
        self._initialize_redis()

    def _initialize_redis(self):
        """Initialize Redis client based on environment."""
        if not REDIS_AVAILABLE:
            logger.warning(" Redis not available, caching disabled")
            return

        try:
            # Get Redis URL from environment
            redis_url = os.getenv('REDIS_URL') or os.getenv('REDIS_URL_TEST', 'redis://localhost:6379/0')

            if redis_url:
                # Parse URL to determine connection type
                parsed = urlparse(redis_url)

                if parsed.scheme == 'rediss':
                    # Production - Upstash Redis Cloud with SSL
                    self.redis_client = redis.from_url(
                        redis_url,
                        ssl_cert_reqs=None,  # Disable SSL verification for cloud Redis
                        decode_responses=True,
                        socket_connect_timeout=5,
                        socket_timeout=5,
                        retry_on_timeout=True,
                        health_check_interval=30
                    )
                    logger.info("Connected to Redis Cloud (production)")

                elif parsed.scheme == 'redis':
                    # Development - Local Redis
                    self.redis_client = redis.from_url(
                        redis_url,
                        decode_responses=True,
                        socket_connect_timeout=2,
                        socket_timeout=5
                    )
                    logger.info("Connected to Local Redis (development)")

                else:
                    raise ValueError(f"Unsupported Redis scheme: {parsed.scheme}")

                # Test connection
                self.redis_client.ping()
                logger.info("Redis connection successful")

            else:
                # Fallback to default local connection
                self.redis_client = redis.Redis(
                    host='localhost',
                    port=6379,
                    db=0,
                    decode_responses=True,
                    socket_connect_timeout=2
                )
                self.redis_client.ping()
                logger.info("Connected to default local Redis")

        except Exception as e:
            logger.warning(f"Redis connection failed: {e}. Running without cache.")
            self.redis_client = None

    def get_client(self) -> Optional[Redis]:
        """Get Redis client instance."""
        return self.redis_client

    def is_available(self) -> bool:
        """Check if Redis is available."""
        return self.redis_client is not None

    def get_connection_info(self) -> dict:
        """Get connection information."""
        if not self.redis_client:
            return {"status": "disconnected", "type": "none"}

        try:
            info = self.redis_client.connection_pool.connection_kwargs
            redis_url = os.getenv('REDIS_URL', 'local')

            return {
                "status": "connected",
                "type": "cloud" if "upstash" in redis_url else "local",
                "host": info.get("host", "unknown"),
                "port": info.get("port", "unknown"),
                "db": info.get("db", 0)
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}


# Global Redis configuration instance
redis_config = RedisConfig()
