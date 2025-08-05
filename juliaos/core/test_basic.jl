# Simplified test script to validate basic JuliaOS integration
# This script tests only basic modules without complex dependencies

println("Starting simplified JuliaOS integration test...")

# Add current directory to load path
push!(LOAD_PATH, pwd())

try
    println("Testing basic modules...")

    # Test basic modules individually first
    include("src/agents/CommonTypes.jl")
    using .CommonTypes
    println("✓ CommonTypes module imported successfully")

    include("src/resources/Resources.jl")
    using .Resources
    println("✓ Resources module imported successfully")

    # Test Tools module
    include("src/tools/Tools.jl")
    using .Tools
    println("✓ Tools module imported successfully")
    println("Available tools: $(length(TOOL_REGISTRY)) tools registered")

    # Test Strategies module
    include("src/strategies/Strategies.jl")
    using .Strategies
    println("✓ Strategies module imported successfully")
    println("Available strategies: $(length(STRATEGY_REGISTRY)) strategies registered")

    # Test DetectiveAgents module
    include("src/agents/DetectiveAgents.jl")
    using .DetectiveAgents
    println("✓ DetectiveAgents module imported successfully")

    println("\n🎉 Basic modules integrated successfully!")
    println("Ghost Wallet Hunter core modules are working.")

    # Test specific Ghost Wallet Hunter tools
    if haskey(TOOL_REGISTRY, "analyze_wallet")
        println("✓ Ghost Wallet Hunter analyze_wallet tool is registered")
    end

    if haskey(TOOL_REGISTRY, "detective_swarm")
        println("✓ Ghost Wallet Hunter detective_swarm tool is registered")
    end

    if haskey(STRATEGY_REGISTRY, "detective_investigation")
        println("✓ Ghost Wallet Hunter detective_investigation strategy is registered")
    end

catch e
    println("❌ Error during simplified integration test:")
    println(e)
    rethrow(e)
end
