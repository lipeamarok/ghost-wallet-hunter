# 🚀 Ghost Wallet Hunter - Julia Core Service
# Pure Julia service for AI analysis and database operations

FROM julia:1.11-bullseye

# Build info
LABEL maintainer="Ghost Wallet Hunter Team"
LABEL description="Julia Core Service for Ghost Wallet Hunter - AI & Database"

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

# 📁 Copy Julia project files first
COPY core/Project.toml ./
COPY core/Manifest.toml ./

# ⚡ Install Julia dependencies
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia dependencies installed successfully");'

# � Copy Julia core application code
COPY core/ ./core/

# Set environment variables for Julia service
ENV HOST=0.0.0.0
ENV PORT=8052
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_PROJECT=/app

# Health check for Julia service
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose Julia service port
EXPOSE 8052

# Start Julia server
CMD ["julia", "core/start_julia_server.jl"]
