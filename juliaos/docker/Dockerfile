# 🚀 Ghost Wallet Hunter - Optimized Julia Service for Render.com
FROM julia:1.11-bullseye

# 🔧 Install system dependencies (minimal set for performance)
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    postgresql-client \
    libpq-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 📁 Set working directory
WORKDIR /app

# 📋 Copy Project.toml first (Docker layer caching)
COPY core/Project.toml ./

# 📁 Copy all source code BEFORE precompilation (JuliaOS needs source files)
COPY core/ ./

# 📦 Install Julia dependencies and precompile (now with source files available)
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia dependencies installed and precompiled!");'

# 🌐 Environment variables optimized for Render
ENV HOST=0.0.0.0
ENV PORT=10000
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_PROJECT=/app
ENV JULIA_THREADS=auto
ENV JULIA_NUM_GC_THREADS=1
ENV GHOST_MODE=production
ENV RENDER=true

# 🩺 Health check optimized for Render's requirements
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# 🔌 Expose port
EXPOSE 10000

# 🚀 Start Ghost Wallet Hunter
CMD ["julia", "--project=.", "--threads=auto", "src/main.jl"]
