# 🚀 Ghost Wallet Hunter - Julia Core Service (FULL VERSION - 2GB)
FROM julia:1.11-bullseye

WORKDIR /app

# 📦 Install ALL system dependencies (no more restrictions!)
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    libpq-dev \
    build-essential \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 📁 Copy Julia project structure completely
COPY core/ ./

# 💪 Use FULL Project.toml with ALL dependencies (no more minimal!)
# Project.toml already has everything: Flux, PyCall, LibPQ, etc.

# ⚡ Install Julia dependencies with FULL power (2GB available!)
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia FULL dependencies installed and precompiled!");'

# Set environment variables for FULL performance
ENV HOST=0.0.0.0
ENV PORT=8052
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_PROJECT=/app
ENV JULIA_NUM_THREADS=4
ENV JULIA_NUM_GC_THREADS=2

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE 8052

# Start FULL JuliaOS server (no more minimal restrictions!)
CMD ["julia", "--project=.", "start_julia_server.jl"]
