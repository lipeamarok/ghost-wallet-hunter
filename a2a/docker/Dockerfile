# A2A Protocol Server - Ultra Lightweight for Render Starter Plan
# Optimized for 512MB RAM limit

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install only essential system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first for better caching
COPY requirements-minimal.txt ./

# Install Python dependencies with minimal memory usage
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements-minimal.txt \
    && pip cache purge

# Copy minimal server only
COPY minimal_server.py ./

# Set environment variables for memory optimization
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV HOST=0.0.0.0
ENV A2A_PORT=10000
ENV JULIA_HOST=https://ghost-wallet-hunter-juliaos.onrender.com

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=10s --retries=2 \
    CMD curl -f http://localhost:${A2A_PORT}/health || exit 1

# Expose port
EXPOSE 10000

# Start minimal server directly
CMD ["python", "minimal_server.py"]
