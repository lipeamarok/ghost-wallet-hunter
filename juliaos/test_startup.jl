#!/usr/bin/env julia

# Test script for JuliaOS startup with fixed functions
println("🔥 Testing JuliaOS Startup with Fixed Functions")
println("=" ^ 50)

# Change to core directory
cd("core")

# Load JuliaOS
try
    println("📦 Loading JuliaOS module...")
    include("src/JuliaOS.jl")
    using .JuliaOS
    println("✅ JuliaOS loaded successfully!")

    # Test Configuration.get_environment()
    println("\n🧪 Testing Configuration.get_environment()...")
    try
        env = JuliaOS.Configuration.get_environment()
        println("✅ Environment: $env")
    catch e
        println("❌ get_environment() failed: $e")
    end

    # Test DetectiveAgents.create_detective_squad()
    println("\n🧪 Testing DetectiveAgents.create_detective_squad()...")
    try
        squad = JuliaOS.DetectiveAgents.create_detective_squad()
        println("✅ Detective squad created with $(length(squad)) detectives")

        # Show first detective info
        if length(squad) > 0
            first_detective = squad[1]
            println("👮 First detective type: $(typeof(first_detective))")
        end
    catch e
        println("❌ create_detective_squad() failed: $e")
    end

    # Now test the server startup
    println("\n🚀 Testing JuliaOS.start_server()...")
    try
        # This should now work without UndefVarError
        @info "Starting server..."
        JuliaOS.start_server()
    catch e
        println("❌ start_server() failed: $e")
        println("Error details: $(typeof(e))")
        if isa(e, LoadError)
            println("Underlying error: $(e.error)")
        end
    end

catch e
    println("❌ Failed to load JuliaOS: $e")
    println("Error type: $(typeof(e))")
    if isa(e, LoadError)
        println("Underlying error: $(e.error)")
    end
end
