# 🔥 GHOST WALLET HUNTER - A2A PROTOCOL START
# Sistema A2A integrado ao JuliaOS Core

"""
    A2A Protocol Startup Module

    Inicialização do protocolo A2A para coordenação de agentes
    NOTA: A2A agora está INTEGRADO ao core, não é mais serviço separado
"""

using Pkg
Pkg.activate("..")

# Core imports
using HTTP
using JSON3
using Redis
using Dates
using UUIDs
using Logging

# Load A2A core
include("A2AProtocol.jl")
using .A2AProtocol

include("MessageBroker.jl")
using .MessageBroker

# Load configuration
include("../config/Configuration.jl")
using .Configuration

"""
    start_a2a_integrated()

    Start A2A Protocol in integrated mode (part of main JuliaOS server)
"""
function start_a2a_integrated()
    println("🔗 Starting A2A Protocol (Integrated Mode)")
    println("📡 Mode: INTEGRATED with JuliaOS Core")
    println("🚫 Standalone Server: DISABLED")
    println("=" ^ 50)

    try
        # Load configuration
        Configuration.load_config()

        # Initialize A2A Protocol
        @info "🔗 Initializing A2A Protocol..."
        A2AProtocol.initialize()

        # Initialize Message Broker
        @info "📨 Starting Message Broker..."
        MessageBroker.start_broker()

        @info "✅ A2A Protocol initialized successfully (integrated mode)"

        return true

    catch e
        @error "❌ Failed to initialize A2A Protocol" exception=e
        return false
    end
end

"""
    start_a2a_standalone()

    Start A2A Protocol as standalone server (DEPRECATED)
    NOTA: Esta função é mantida apenas para compatibilidade temporária
"""
function start_a2a_standalone()
    @warn "🚨 A2A Standalone mode is DEPRECATED"
    @warn "🔄 Use integrated mode instead (part of main.jl)"

    println("🔗 Starting A2A Protocol (DEPRECATED Standalone Mode)")
    println("⚠️  WARNING: This mode will be REMOVED soon")
    println("🔄 Migrate to integrated mode: julia main.jl")
    println("=" ^ 50)

    try
        # Load configuration
        Configuration.load_config()

        # Start standalone server (temporary)
        host = get_config(:A2A_HOST, "0.0.0.0")
        port = get_config(:A2A_PORT, 9100)

        @info "🔗 Starting A2A standalone server..." host port

        # Initialize A2A
        A2AProtocol.initialize()
        MessageBroker.start_broker()

        # Create simple HTTP server for A2A
        function handle_a2a_request(req::HTTP.Request)
            try
                if req.target == "/health"
                    return HTTP.Response(200, JSON3.write(Dict(
                        "status" => "healthy",
                        "service" => "a2a-protocol",
                        "mode" => "standalone-deprecated",
                        "timestamp" => now()
                    )))
                elseif req.target == "/agents"
                    agents = A2AProtocol.list_agents()
                    return HTTP.Response(200, JSON3.write(Dict(
                        "agents" => agents,
                        "count" => length(agents)
                    )))
                else
                    return HTTP.Response(404, "A2A Endpoint not found")
                end
            catch e
                @error "A2A request error" exception=e
                return HTTP.Response(500, "Internal A2A Error")
            end
        end

        @info "✅ A2A Protocol server started (DEPRECATED MODE)"
        @info "🌐 A2A Server: http://$host:$port"
        @info "📋 A2A Health: http://$host:$port/health"

        # Start server (blocking)
        HTTP.serve(handle_a2a_request, host, port)

    catch e
        @error "❌ Failed to start A2A Protocol standalone server" exception=e
        rethrow(e)
    end
end

"""
    main()

    Main entry point - defaults to integrated mode
"""
function main()
    mode = get(ENV, "A2A_MODE", "integrated")

    if mode == "standalone"
        @warn "🚨 Starting in DEPRECATED standalone mode"
        start_a2a_standalone()
    else
        @info "🔗 A2A Protocol running in integrated mode"
        start_a2a_integrated()
    end
end

# Auto-start if run directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
