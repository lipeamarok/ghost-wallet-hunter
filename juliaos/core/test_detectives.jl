#!/usr/bin/env julia

# Test script for consolidated DetectiveAgents
println("🔧 Testing consolidated DetectiveAgents...")

try
    include("src/agents/DetectiveAgents.jl")
    using .DetectiveAgents

    println("✅ DetectiveAgents module loaded successfully!")

    # Test getting all detectives
    detectives = get_all_detectives()
    println("🕵️ Available detectives: $(length(detectives))")

    for detective in detectives
        println("  • $(detective["name"]) - $(detective["specialty"])")
    end

    # Test creating specific detective
    println("\n🔧 Testing detective creation...")
    poirot = create_detective_by_type("poirot")
    println("✅ Created Poirot: $(poirot.detective.name)")

    marple = create_detective_by_type("marple")
    println("✅ Created Marple: $(marple.detective.name)")

    println("\n🎉 FASE 2.2 COMPLETE - Consolidated definitions working!")

catch e
    println("❌ Error testing DetectiveAgents: $e")
    exit(1)
end
