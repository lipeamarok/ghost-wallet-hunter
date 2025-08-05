# 🚀 Ghost Wallet Hunter - JuliaOS + A2A Service
# Unified Dockerfile for Render deployment with A2A integration

FROM julia:1.11-bullseye

# Build info
LABEL maintainer="Ghost Wallet Hunter Team"
LABEL description="JuliaOS Backend + A2A Communication for Ghost Wallet Hunter"

WORKDIR /app

# 📦 Install system dependencies including Python for A2A
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    libpq-dev \
    build-essential \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 📁 Copy project files
COPY core/Project.toml ./

# 📄 Copy all application code first (needed for JuliaOS package)
COPY . ./

# ⚡ Install Julia dependencies
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    println("✅ Julia dependencies installed successfully");'

# 🐍 Install Python A2A dependencies
COPY a2a/pyproject.toml ./a2a/pyproject.toml
COPY python/pyproject.toml ./python/pyproject.toml
COPY a2a/ ./a2a/
COPY python/ ./python/

RUN pip3 install --upgrade pip && \
    cd python && pip3 install . && \
    cd ../a2a && pip3 install . && \
    echo "✅ A2A dependencies installed successfully"

# 📋 Create supervisor configuration
COPY docker/supervisor.conf /etc/supervisor/conf.d/ghost-services.conf

# 🔍 Debug: Verify installation
RUN ls -la /app/ && \
    julia --project=. -e 'using Pkg; Pkg.status()' && \
    python3 -c "import juliaos; import a2a; print('✅ All imports working')"

# 🛡️ Security: Create non-root user
RUN useradd -m -u 1001 juliaos && \
    chown -R juliaos:juliaos /app && \
    mkdir -p /var/log/supervisor && \
    chown -R juliaos:juliaos /var/log/supervisor

USER juliaos

# 🌐 Environment variables
ENV JULIA_PROJECT=@.
ENV JULIA_DEPOT_PATH=/app/.julia
ENV JULIA_NUM_THREADS=auto
ENV HOST=0.0.0.0
ENV PORT=8052
ENV A2A_PORT=9100

# 📡 Expose ports
EXPOSE 8052 9100

# 🎬 Start both services with supervisor
CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/ghost-services.conf"]
