# A2A Protocol Server - Lightweight Service
# Located at: juliaos/a2a/docker/Dockerfile

FROM python:3.11-slim

# Set working directory specific for A2A
WORKDIR /app/a2a

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy A2A requirements first (for better caching)
COPY requirements-a2a.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements-a2a.txt

# Copy A2A source code with correct structure
COPY src/ ./src/

# Set environment variables
ENV HOST=0.0.0.0
ENV A2A_PORT=10000
ENV JULIA_HOST=https://ghost-wallet-hunter-juliaos.onrender.com

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${A2A_PORT}/health || exit 1

# Expose port
EXPOSE 10000

# Start A2A server as module to handle relative imports
# Start A2A server with correct path
CMD ["python", "-m", "a2a.server"]
