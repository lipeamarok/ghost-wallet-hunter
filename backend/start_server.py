#!/usr/bin/env python3
"""
Ghost Wallet Hunter Server Launcher
Enhanced with JuliaOS AI-powered transaction analysis
"""

import os
import sys
import uvicorn
from pathlib import Path

def main():
    """Start the Ghost Wallet Hunter server."""

    # Ensure we're in the correct directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)

    # Add current directory to Python path
    sys.path.insert(0, str(backend_dir))

    print("🚀 Starting Ghost Wallet Hunter Server")
    print("=" * 50)
    print("🔍 Enhanced with JuliaOS AI Analysis")
    print("🤖 AI-powered transaction pattern detection")
    print("🎯 Blockchain compliance monitoring")
    print("=" * 50)

    try:
        # Test import main module
        import main
        print("✅ Main module imported successfully")
        print(f"✅ FastAPI app: {main.app}")

        # Start the server
        print("\n🌐 Server starting on http://localhost:8001")
        print("📊 API Documentation: http://localhost:8001/docs")
        print("🔄 Health Check: http://localhost:8001/health")
        print("📈 Analysis Endpoint: http://localhost:8001/api/v1/analyze")

        uvicorn.run(
            main.app,
            host="0.0.0.0",
            port=8001,
            log_level="info",
            reload=False  # Disable reload to avoid import issues
        )

    except ImportError as e:
        print(f"❌ Failed to import main module: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Server startup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
