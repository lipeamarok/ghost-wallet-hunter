# 🚀 Ghost Wallet Hunter - JuliaOS Service
# Simple Dockerfile for Render deployment

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

# 📁 Copy project files
COPY Project.toml ./
COPY Manifest.toml ./

# ⚡ Install Julia dependencies
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia dependencies installed successfully");'

# 📄 Copy all application code
COPY . ./

#  Security: Create non-root user
RUN useradd -m -u 1001 juliaos && \
    chown -R juliaos:juliaos /app

USER juliaos

# 🌐 Environment variables
ENV JULIA_PROJECT=@.
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_NUM_THREADS=auto
ENV HOST=0.0.0.0

# 📡 Expose port (Render will set PORT env var)
EXPOSE 8052

# 🎬 Start command
CMD ["julia", "--project=@.", "start_julia_server.jl"]
