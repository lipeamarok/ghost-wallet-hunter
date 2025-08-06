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

# ⚡ Install Julia dependencies with AGGRESSIVE MEMORY OPTIMIZATION!
RUN julia --project=. -e '\
    ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"; \
    using Pkg; \
    Pkg.instantiate(); \
    println("✅ Dependencies installed WITHOUT precompilation!"); \
    println("All compilation will happen during runtime - saves 1.5GB+ memory");'

# Set environment variables for MEMORY-OPTIMIZED performance
ENV HOST=0.0.0.0
ENV PORT=10000
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_PROJECT=/app
ENV JULIA_NUM_THREADS=2
ENV JULIA_NUM_GC_THREADS=1
ENV JULIA_PKG_PRECOMPILE_AUTO=0
ENV JULIA_COPY_STACKS=1

# Health check com timeout maior para permitir compilação
HEALTHCHECK --interval=45s --timeout=15s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port (Render default)
EXPOSE 10000

# 🚀 QUICK START: Bind porta imediatamente, depois carrega sistema completo
CMD ["julia", "--project=.", "quick_start.jl"]
