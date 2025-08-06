#!/usr/bin/env julia

"""
Test script for detective agent integration
"""

using Pkg
using Dates  # Necessário para now()

println("🧪 Testing Detective Agent Integration...")

# Activate project environment
Pkg.activate(".")

try
    # Test 1: Import framework
    println("📦 Testing JuliaOSFramework import...")
    include("src/framework/JuliaOSFramework.jl")
    println("✅ JuliaOSFramework imported successfully")
    
    # Test 2: Check detective registry
    println("📋 Testing detective registry...")
    detectives = JuliaOSFramework.DetectiveAgents.get_detective_registry()
    println("✅ Detective registry loaded: $(length(detectives)) detectives")
    
    # Test 3: Create detective agent
    println("🕵️ Testing detective creation...")
    agent = JuliaOSFramework.create_detective_agent("poirot")
    if !isnothing(agent)
        println("✅ Detective agent created: $(agent["name"])")
    else
        println("❌ Failed to create detective agent")
    end
    
    # Test 4: Test investigation function
    println("🔍 Testing investigation function...")
    test_wallet = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2" # Bitcoin example
    result = JuliaOSFramework.start_investigation("poirot", test_wallet)
    if haskey(result, "status")
        println("✅ Investigation completed with status: $(result["status"])")
    else
        println("❌ Investigation failed")
    end
    
    println("\n🎉 Integration test completed!")
    
catch e
    println("❌ Test failed with error: $e")
    println("Stack trace:")
    println(stacktrace(catch_backtrace()))
end