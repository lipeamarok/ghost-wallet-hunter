# 🚀 Ghost Wallet Hunter - JuliaOS Service
# Complete Dockerfile for Render deployment

FROM julia:1.11-bullseye

# Build info
LABEL maintainer="Ghost Wallet Hunter Team"
LABEL description="JuliaOS Backend for Ghost Wallet Hunter"

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

# 📁 Copy project files in correct order for layer caching
COPY Project.toml Manifest.toml ./

# ⚡ Install Julia dependencies (cached layer)
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia dependencies installed successfully");'

# 📄 Copy application code
COPY . ./backend/
COPY ../julia/ ./julia/
COPY ../config/ ./config/
COPY ../db/ ./db/

# 🔧 Create startup script for Render
RUN echo '#!/usr/bin/env julia' > /app/start.jl && \
    echo 'println("🚀 Starting JuliaOS on Render...")' >> /app/start.jl && \
    echo 'host = get(ENV, "HOST", "0.0.0.0")' >> /app/start.jl && \
    echo 'port = parse(Int, get(ENV, "PORT", "8052"))' >> /app/start.jl && \
    echo 'println("📡 Server starting on $host:$port")' >> /app/start.jl && \
    echo 'include("backend/start_julia_server.jl")' >> /app/start.jl

# 🔒 Security: Create non-root user
RUN useradd -m -u 1001 juliaos && \
    chown -R juliaos:juliaos /app && \
    chmod +x /app/start.jl

USER juliaos

# 🌐 Environment variables
ENV JULIA_PROJECT=@.
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_NUM_THREADS=auto
ENV HOST=0.0.0.0

# 🔍 Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8052}/health || exit 1

# 📡 Expose dynamic port (Render sets PORT automatically)
EXPOSE $PORT

# 🎬 Start command
CMD ["julia", "--project=@.", "/app/start.jl"]
