#!/bin/bash
# Start script for JuliaOS with A2A support

echo "🚀 Starting Ghost Wallet Hunter - JuliaOS"

# Start Julia server in background
echo "📡 Starting Julia Server (port 8052)..."
cd /app/core
julia --project=. start_julia_server.jl &
JULIA_PID=$!

# Wait for Julia server to be ready
echo "⏳ Waiting for Julia server..."
sleep 10

# Start A2A server
echo "🔗 Starting A2A Server (port 9100)..."
cd /app/a2a/src/a2a
python3 server.py &
A2A_PID=$!

# Function to handle shutdown
shutdown() {
    echo "🛑 Shutting down servers..."
    kill $JULIA_PID $A2A_PID
    exit 0
}

# Trap signals
trap shutdown SIGTERM SIGINT

# Keep running
echo "✅ Both servers running. JuliaOS ready!"
wait
