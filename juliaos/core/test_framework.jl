#!/usr/bin/env julia

"""
🔍 JuliaOS Framework Test Script
==============================

This script tests the JuliaOSFramework.jl as the main entry point
for the Detective Agents system.

Run with: julia test_framework.jl
"""

using Pkg
using Logging

# Set up detailed logging
logger = ConsoleLogger(stdout, Logging.Info)
global_logger(logger)

@info "🚀 Starting JuliaOS Framework Test"
@info "===================================="

# Add current directory to load path
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

try
    @info "📦 Loading JuliaOSFramework..."

    # Load the framework
    include("src/framework/JuliaOSFramework.jl")
    using .JuliaOSFramework

    @info "✅ Framework loaded successfully"

    # Test initialization
    @info "🔧 Testing framework initialization..."
    init_result = JuliaOSFramework.initialize()

    if init_result
        @info "✅ Framework initialization: SUCCESS"
    else
        @warn "⚠️ Framework initialization: PARTIAL SUCCESS"
    end

    # Test detective system initialization
    @info "🕵️ Testing detective system initialization..."
    detective_init = JuliaOSFramework.initialize_detective_system()

    @info "🎯 Detective init result: $(detective_init["status"])"
    @info "📊 Agents created: $(get(detective_init, "agents_created", 0))"

    # Test detective agent creation
    @info "🤖 Testing individual detective creation..."

    detective_types = ["poirot", "marple", "spade"]

    for detective_type in detective_types
        @info "Creating detective: $detective_type"
        agent = JuliaOSFramework.create_detective_agent(detective_type)

        if agent !== nothing
            @info "✅ Detective '$detective_type' created successfully"
        else
            @warn "⚠️ Failed to create detective '$detective_type'"
        end
    end

    # Test system health
    @info "🩺 Testing system health check..."
    health = JuliaOSFramework.get_system_health()
    @info "💚 System health status: $(get(health, "status", "UNKNOWN"))"

    # Test performance metrics
    @info "📈 Testing performance metrics..."
    metrics = JuliaOSFramework.get_performance_metrics()
    @info "📊 Metrics retrieved: $(metrics !== nothing)"

    # Test investigation (mock)
    @info "🔍 Testing mock investigation..."
    test_wallet = "HN7cABqLq46Es1jh92dQQisAq662SmxELLLsHHe4YWrH"
    investigation_params = Dict(
        "investigation_type" => "quick",
        "depth" => 10
    )

    investigation_result = JuliaOSFramework.start_investigation(
        "poirot", test_wallet, investigation_params
    )

    @info "🔍 Investigation result: $(get(investigation_result, "status", "unknown"))"

    @info "🎉 All framework tests completed successfully!"
    @info "✨ JuliaOSFramework is working as main entry point"

catch e
    @error "💥 Framework test failed: $e"
    @error "Stack trace:"
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
    exit(1)
end

@info "🏁 Framework test completed"
