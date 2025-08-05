# 🚀 Ghost Wallet Hunter - Julia Core Service
FROM julia:1.11-bullseye

WORKDIR /app

# 📦 Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    libpq-dev \
    build-essential \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 📁 Copy Julia project structure completely
COPY core/ ./

# ⚡ Install Julia dependencies
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    println("✅ Julia dependencies installed successfully");'

# Set environment variables
ENV HOST=0.0.0.0
ENV PORT=8052
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_PROJECT=/app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE 8052

# Start server
CMD ["julia", "start_julia_server.jl"]
