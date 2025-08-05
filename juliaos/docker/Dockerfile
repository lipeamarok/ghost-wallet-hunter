# 🚀 Ghost Wallet Hunter - Julia Core Service (Memory Optimized)
FROM julia:1.11-bullseye

WORKDIR /app

# 📦 Install minimal system dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# 📁 Copy Julia project structure completely
COPY core/ ./

# Use minimal dependencies to save memory during build
RUN cp Project.minimal.toml Project.toml

# ⚡ Install Julia dependencies with aggressive memory optimization
RUN JULIA_NUM_THREADS=1 julia --project=. --optimize=0 --check-bounds=no --math-mode=fast -e '\
    using Pkg; \
    Pkg.instantiate(); \
    println("✅ Julia dependencies installed successfully");' \
    && rm -rf ~/.julia/logs \
    && rm -rf ~/.julia/scratchspaces

# Set environment variables for memory optimization
ENV HOST=0.0.0.0
ENV PORT=8052
ENV JULIA_DEPOT_PATH=/tmp/.julia
ENV JULIA_PROJECT=/app
ENV JULIA_NUM_THREADS=1
ENV JULIA_NUM_GC_THREADS=1
ENV JULIA_MAX_NUM_PRECOMPILE_FILES=50

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE 8052

# Start server with memory constraints
CMD ["julia", "--optimize=0", "--check-bounds=no", "start_julia_server.jl"]
