"""A2A (Agent-to-Agent) Protocol Service Setup"""
from setuptools import setup, find_packages

setup(
    name="a2a-service",
    version="1.0.0",
    description="Agent-to-Agent Protocol Service for Ghost Wallet Hunter",
    author="Ghost Wallet Hunter Team",
    author_email="team@ghostwallethunter.com",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9",
    install_requires=[
        "starlette>=0.27.0",
        "uvicorn[standard]>=0.23.0",
        "httpx>=0.24.0",
        "pydantic>=2.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-asyncio>=0.21.0",
        ]
    },
    entry_points={
        "console_scripts": [
            "a2a-server=a2a.server:main",
        ]
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
)
