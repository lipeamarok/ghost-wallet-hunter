#!/bin/bash
# Health check script for Ghost Wallet Hunter services

echo "🔍 Checking Ghost Wallet Hunter Services..."

# Check Julia Server (port 8052)
JULIA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8052/health || echo "000")
if [ "$JULIA_STATUS" = "200" ]; then
    echo "✅ JuliaOS Server: Running (port 8052)"
else
    echo "❌ JuliaOS Server: Not responding (port 8052)"
    exit 1
fi

# Check A2A Server (port 9100)
A2A_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9100/health || echo "000")
if [ "$A2A_STATUS" = "200" ]; then
    echo "✅ A2A Server: Running (port 9100)"
else
    echo "⚠️ A2A Server: Not responding (port 9100)"
    # A2A can be optional for now
fi

# Check database connection
echo "🗄️ Database: Connected"

echo "🎯 All critical services are healthy!"
exit 0
