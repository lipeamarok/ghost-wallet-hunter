#!/bin/bash
# Ghost Wallet Hunter - Production Deployment Script
# Deploys the complete system with all components

set -e

echo "🚀 Ghost Wallet Hunter - Production Deployment"
echo "============================================="

# Check if required environment variables are set
check_env_vars() {
    echo "🔍 Checking environment variables..."

    required_vars=(
        "OPENAI_API_KEY"
        "DB_PASSWORD"
    )

    missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "❌ Missing required environment variables:"
        printf '%s\n' "${missing_vars[@]}"
        echo ""
        echo "Please set these variables before deploying:"
        echo "export OPENAI_API_KEY=your_openai_key"
        echo "export GROK_API_KEY=your_grok_key (optional)"
        echo "export DB_PASSWORD=your_secure_password"
        exit 1
    fi

    echo "✅ All required environment variables are set"
}

# Create data directories
create_directories() {
    echo "📁 Creating data directories..."

    mkdir -p backend/data/ai_costs
    mkdir -p backend/data/logs
    mkdir -p database/backups
    mkdir -p nginx/ssl

    echo "✅ Data directories created"
}

# Generate SSL certificates (self-signed for development)
generate_ssl() {
    echo "🔐 Generating SSL certificates..."

    if [ ! -f nginx/ssl/cert.pem ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=GhostWalletHunter/CN=ghostwallethunter.xyz"

        echo "✅ SSL certificates generated"
    else
        echo "✅ SSL certificates already exist"
    fi
}

# Setup database initialization
setup_database() {
    echo "🗄️ Setting up database initialization..."

    cat > database/init.sql << 'EOF'
-- Ghost Wallet Hunter Database Initialization
-- Creates necessary tables and indexes

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address VARCHAR(44) UNIQUE NOT NULL,
    risk_score FLOAT DEFAULT 0.0,
    last_analyzed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    analysis_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI cost tracking table
CREATE TABLE IF NOT EXISTS ai_costs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL,
    detective VARCHAR(50) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    total_tokens INTEGER NOT NULL,
    cost DECIMAL(10,6) NOT NULL,
    analysis_type VARCHAR(100) NOT NULL,
    success BOOLEAN NOT NULL,
    response_time FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investigations table
CREATE TABLE IF NOT EXISTS investigations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_address VARCHAR(44) NOT NULL,
    investigation_type VARCHAR(50) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'in_progress',
    results JSONB,
    cost DECIMAL(10,6) DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_wallets_address ON wallets(address);
CREATE INDEX IF NOT EXISTS idx_wallets_risk_score ON wallets(risk_score);
CREATE INDEX IF NOT EXISTS idx_ai_costs_user_id ON ai_costs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_costs_detective ON ai_costs(detective);
CREATE INDEX IF NOT EXISTS idx_ai_costs_created_at ON ai_costs(created_at);
CREATE INDEX IF NOT EXISTS idx_investigations_wallet ON investigations(wallet_address);
CREATE INDEX IF NOT EXISTS idx_investigations_user ON investigations(user_id);
CREATE INDEX IF NOT EXISTS idx_investigations_status ON investigations(status);

-- Insert sample data (optional)
INSERT INTO wallets (address, risk_score) VALUES
    ('11111111111111111111111111111112', 0.1),
    ('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA', 0.05)
ON CONFLICT (address) DO NOTHING;

COMMIT;
EOF

    echo "✅ Database initialization script created"
}

# Setup Nginx configuration
setup_nginx() {
    echo "🌐 Setting up Nginx configuration..."

    mkdir -p nginx

    cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8000;
    }

    upstream frontend {
        server frontend:3000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
    limit_req_zone $binary_remote_addr zone=web:10m rate=120r/m;

    server {
        listen 80;
        server_name ghostwallethunter.xyz www.ghostwallethunter.xyz;

        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl;
        server_name ghostwallethunter.xyz www.ghostwallethunter.xyz;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # Frontend routes
        location / {
            limit_req zone=web burst=20 nodelay;
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Backend API routes
        location /api/ {
            limit_req zone=api burst=10 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # CORS headers
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        }

        # WebSocket support for real-time updates
        location /ws/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
    }
}
EOF

    echo "✅ Nginx configuration created"
}

# Build and deploy
deploy() {
    echo "🚢 Building and deploying containers..."

    # Pull latest images
    docker-compose pull

    # Build custom images
    docker-compose build --no-cache

    # Start services
    docker-compose up -d

    echo "✅ Deployment complete!"
}

# Health check
health_check() {
    echo "🏥 Performing health checks..."

    # Wait for services to start
    sleep 30

    # Check backend health
    if curl -f http://localhost:8000/api/health > /dev/null 2>&1; then
        echo "✅ Backend health check passed"
    else
        echo "❌ Backend health check failed"
        return 1
    fi

    # Check frontend health
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Frontend health check passed"
    else
        echo "❌ Frontend health check failed"
        return 1
    fi

    # Check database connection
    if docker-compose exec -T postgres pg_isready -U ghost_user > /dev/null 2>&1; then
        echo "✅ Database health check passed"
    else
        echo "❌ Database health check failed"
        return 1
    fi

    echo "🌟 All health checks passed!"
}

# Show status
show_status() {
    echo ""
    echo "🎯 Ghost Wallet Hunter - Deployment Status"
    echo "=========================================="

    echo "📊 Container Status:"
    docker-compose ps

    echo ""
    echo "🌐 Access URLs:"
    echo "Frontend (HTTPS): https://ghostwallethunter.xyz"
    echo "Backend API: https://api.ghostwallethunter.xyz"
    echo "API Documentation: https://api.ghostwallethunter.xyz/docs"
    echo "Cost Dashboard: https://api.ghostwallethunter.xyz/ai-costs/dashboard"

    echo ""
    echo "🔧 Management Commands:"
    echo "View logs: docker-compose logs -f [service]"
    echo "Stop system: docker-compose down"
    echo "Update system: docker-compose pull && docker-compose up -d"
    echo "Backup database: docker-compose exec postgres pg_dump -U ghost_user ghost_wallet_hunter > backup.sql"
}

# Main deployment process
main() {
    check_env_vars
    create_directories
    generate_ssl
    setup_database
    setup_nginx
    deploy
    health_check
    show_status
}

# Run deployment
main "$@"
