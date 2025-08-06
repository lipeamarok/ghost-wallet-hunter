#!/usr/bin/env julia

"""
🕵️ Ghost Wallet Hunter - Main Entry Point
=========================================

This is the main entry point for the Ghost Wallet Hunter system using JuliaOSFramework.

Usage:
    julia main.jl                           # Start the system
    julia main.jl --test                    # Run tests
    julia main.jl --health                  # Check system health
    julia main.jl --investigate <wallet>    # Investigate a wallet
"""

using Pkg
using Logging

# Parse command line arguments
const ARGS_DICT = Dict(
    "--test" => length(ARGS) > 0 && "--test" in ARGS,
    "--health" => length(ARGS) > 0 && "--health" in ARGS,
    "--investigate" => length(ARGS) > 1 && "--investigate" in ARGS,
    "wallet" => length(ARGS) > 1 && "--investigate" in ARGS ? ARGS[findfirst(x -> x == "--investigate", ARGS) + 1] : nothing
)

# Set up logging
logger = ConsoleLogger(stdout, Logging.Info)
global_logger(logger)

@info "🚀 Starting Ghost Wallet Hunter"
@info "================================"

# Add current directory to load path
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

try
    # Load the framework
    @info "📦 Loading JuliaOS Framework..."
    include("src/framework/JuliaOSFramework.jl")
    using .JuliaOSFramework

    # Initialize the system
    @info "🔧 Initializing system..."
    init_success = JuliaOSFramework.initialize()

    if !init_success
        @error "❌ System initialization failed"
        exit(1)
    end

    @info "✅ Ghost Wallet Hunter system ready!"

    # Handle command line arguments
    if ARGS_DICT["--test"]
        @info "🧪 Running system tests..."
        include("test_framework.jl")

    elseif ARGS_DICT["--health"]
        @info "🩺 Checking system health..."
        health = JuliaOSFramework.get_system_health()

        println("\n📊 SYSTEM HEALTH REPORT")
        println("========================")
        println("Status: $(get(health, "status", "UNKNOWN"))")
        println("Timestamp: $(get(health, "timestamp", "N/A"))")

        if haskey(health, "agents")
            println("Active Agents: $(length(health["agents"]))")
        end

    elseif ARGS_DICT["--investigate"] && ARGS_DICT["wallet"] !== nothing
        wallet_address = ARGS_DICT["wallet"]
        @info "🔍 Starting investigation for wallet: $wallet_address"

        params = Dict(
            "investigation_type" => "standard",
            "depth" => 20,
            "ai_analysis" => true
        )

        result = JuliaOSFramework.start_investigation("poirot", wallet_address, params)

        println("\n🔍 INVESTIGATION RESULT")
        println("=======================")
        println("Status: $(get(result, "status", "unknown"))")

        if haskey(result, "risk_score")
            println("Risk Score: $(result["risk_score"])")
        end

        if haskey(result, "patterns")
            println("Patterns Detected: $(join(result["patterns"], ", "))")
        end

    else
        # Interactive mode
        @info "🎮 Starting interactive mode..."

        println("\n🕵️ Ghost Wallet Hunter - Interactive Mode")
        println("==========================================")
        println("Available detectives: poirot, marple, spade, marlowe, dupin, shadow, raven")
        println("Type 'help' for commands, 'quit' to exit")

        while true
            print("\nghost-hunter> ")
            input = strip(readline())

            if input == "quit" || input == "exit"
                break
            elseif input == "help"
                println("\nAvailable commands:")
                println("  investigate <detective> <wallet_address>  - Start investigation")
                println("  health                                    - Check system health")
                println("  metrics                                   - Show performance metrics")
                println("  agents                                    - List available agents")
                println("  quit                                      - Exit")

            elseif startswith(input, "investigate")
                parts = split(input)
                if length(parts) >= 3
                    detective = parts[2]
                    wallet = parts[3]

                    @info "🔍 Starting investigation: $detective -> $wallet"
                    result = JuliaOSFramework.start_investigation(detective, wallet, Dict("investigation_type" => "quick"))
                    println("Result: $(get(result, "status", "unknown"))")
                else
                    println("Usage: investigate <detective> <wallet_address>")
                end

            elseif input == "health"
                health = JuliaOSFramework.get_system_health()
                println("System Health: $(get(health, "status", "UNKNOWN"))")

            elseif input == "metrics"
                metrics = JuliaOSFramework.get_performance_metrics()
                println("Metrics available: $(metrics !== nothing)")

            elseif input == "agents"
                agents = JuliaOSFramework.create_all_detective_agents()
                println("Available agents: $(join(keys(agents), ", "))")

            else
                println("Unknown command. Type 'help' for available commands.")
            end
        end
    end

    @info "👋 Ghost Wallet Hunter session ended"

catch e
    @error "💥 System error: $e"

    # Show detailed error for debugging
    @error "Stack trace:"
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end

    exit(1)
end
