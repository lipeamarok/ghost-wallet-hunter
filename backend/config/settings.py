"""
Application Configuration Settings

This module handles all configuration settings for the Ghost Wallet Hunter backend,
including environment variables, database settings, and API configurations.
"""

from pydantic_settings import BaseSettings
from typing import List, Optional
import os
from pathlib import Path

# Get the backend directory path
BACKEND_DIR = Path(__file__).parent.parent


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application Info
    APP_NAME: str = "Ghost Wallet Hunter"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"

    # Security
    SECRET_KEY: str = "change-this-secret-key-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Database
    DATABASE_URL: str = "sqlite:///./ghost_wallet_hunter.db"

    # OpenAI
    OPENAI_API_KEY: Optional[str] = None

    # GROK (X.AI)
    GROK_API_KEY: Optional[str] = None

    # Solana
    SOLANA_RPC_URL: str = "https://api.mainnet-beta.solana.com"
    SOLANA_WS_URL: str = "wss://api.mainnet-beta.solana.com"
    SOLANA_NETWORK: str = "mainnet-beta"

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000", 
        "http://127.0.0.1:3000",
        "https://ghost-wallet-hunter.vercel.app",
        "https://ghost-wallet-hunter-*.vercel.app"  # Para preview deployments
    ]
    ALLOWED_METHODS: List[str] = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    ALLOWED_HEADERS: List[str] = ["*"]

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_BURST: int = 10

    # Cache Settings
    REDIS_URL: str = "redis://localhost:6379/0"
    CACHE_TTL_SECONDS: int = 900

    # Logging
    LOG_LEVEL: str = "INFO"
    SENTRY_DSN: Optional[str] = None

    # Analysis Settings
    MAX_CLUSTER_SIZE: int = 50
    MAX_TRANSACTION_DEPTH: int = 10
    SUSPICIOUS_THRESHOLD: float = 0.7
    MIN_CONNECTIONS_FOR_CLUSTER: int = 3

    # JuliaOS
    JULIAOS_API_KEY: Optional[str] = None
    JULIAOS_ENVIRONMENT: str = "development"

    class Config:
        env_file = BACKEND_DIR / ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Convert string lists to actual lists for CORS settings
        if isinstance(self.ALLOWED_ORIGINS, str):
            self.ALLOWED_ORIGINS = [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
        if isinstance(self.ALLOWED_METHODS, str):
            self.ALLOWED_METHODS = [method.strip() for method in self.ALLOWED_METHODS.split(",")]
        if isinstance(self.ALLOWED_HEADERS, str):
            self.ALLOWED_HEADERS = [header.strip() for header in self.ALLOWED_HEADERS.split(",")]


# Create global settings instance
settings = Settings()


def get_settings() -> Settings:
    """Get application settings instance."""
    return settings
