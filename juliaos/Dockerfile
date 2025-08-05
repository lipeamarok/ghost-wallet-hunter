# JuliaOS Dockerfile with A2A support
FROM julia:1.11.6

# Install Python and pip
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Julia project files
COPY Project.toml Manifest.toml ./
COPY core/ ./core/
COPY a2a/ ./a2a/

# Install Julia dependencies
RUN julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

# Install Python dependencies for A2A
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Install A2A package
RUN cd a2a && pip3 install -e .

# Expose ports
EXPOSE 8052 9100

# Start script that runs both Julia server and A2A server
COPY start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
