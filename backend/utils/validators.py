"""
Validation utilities for Ghost Wallet Hunter.
Simplified for initial setup.
"""

import re
from typing import Optional


def validate_solana_address(address: str) -> bool:
    """
    Validate Solana wallet address format.

    Args:
        address: The wallet address to validate

    Returns:
        bool: True if valid, False otherwise
    """
    try:
        if not address or not isinstance(address, str):
            return False

        # Solana addresses are base58 encoded and typically 32-44 characters
        if len(address) < 32 or len(address) > 44:
            return False

        # Check if it contains only valid base58 characters
        valid_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        if not all(c in valid_chars for c in address):
            return False

        return True

    except Exception:
        return False


def validate_transaction_signature(signature: str) -> bool:
    """
    Validate Solana transaction signature format.

    Args:
        signature: The transaction signature to validate

    Returns:
        bool: True if valid, False otherwise
    """
    try:
        if not signature or not isinstance(signature, str):
            return False

        # Transaction signatures are base58 encoded and typically 88 characters
        if len(signature) != 88:
            return False

        # Check if it contains only valid base58 characters
        valid_chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        if not all(c in valid_chars for c in signature):
            return False

        return True

    except Exception:
        return False


def validate_risk_score(score: float) -> bool:
    """
    Validate risk score is within valid range.

    Args:
        score: The risk score to validate

    Returns:
        bool: True if valid (0.0 to 1.0), False otherwise
    """
    try:
        return isinstance(score, (int, float)) and 0.0 <= score <= 1.0
    except Exception:
        return False
