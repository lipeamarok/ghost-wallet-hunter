"""
Basic Health Check Test

Test to verify the application starts correctly.
"""

import pytest
import asyncio
from fastapi.testclient import TestClient
import sys
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).parent.parent
sys.path.append(str(backend_dir))

from main import app

client = TestClient(app)


def test_root_endpoint():
    """Test the root endpoint returns correct information."""
    response = client.get("/")
    assert response.status_code == 200

    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "status" in data
    assert data["status"] == "operational"


def test_health_endpoint():
    """Test the health check endpoint."""
    response = client.get("/api/health")
    assert response.status_code == 200

    data = response.json()
    assert "status" in data
    assert "timestamp" in data
    assert data["status"] == "healthy"


def test_version_endpoint():
    """Test the version information endpoint."""
    response = client.get("/api/version")
    assert response.status_code == 200

    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "environment" in data


def test_patterns_endpoint():
    """Test the patterns information endpoint."""
    response = client.get("/api/patterns")
    assert response.status_code == 200

    data = response.json()
    assert "patterns" in data
    assert "risk_scoring" in data
    assert isinstance(data["patterns"], dict)


def test_invalid_wallet_analysis():
    """Test analysis with invalid wallet address."""
    response = client.post(
        "/api/analyze",
        json={
            "wallet_address": "invalid_address",
            "depth": 1,
            "include_explanation": False
        }
    )
    assert response.status_code == 422  # Validation error


if __name__ == "__main__":
    pytest.main([__file__])
