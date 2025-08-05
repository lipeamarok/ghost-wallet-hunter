# Test script to validate the consolidated JuliaOS integration
# This script tests that all modules are properly imported and available

using Pkg

println("Starting JuliaOS integration test...")

# Add current directory to load path
push!(LOAD_PATH, pwd())

try
    println("Testing JuliaOS module import...")
    include("src/JuliaOS.jl")
    using .JuliaOS
    println("✓ JuliaOS module imported successfully")

    # Test Tools module
    using .Tools
    println("✓ Tools module imported successfully")
    println("Available tools: $(length(TOOL_REGISTRY)) tools registered")

    # Test Strategies module
    using .Strategies
    println("✓ Strategies module imported successfully")
    println("Available strategies: $(length(STRATEGY_REGISTRY)) strategies registered")

    # Test DetectiveAgents module
    using .DetectiveAgents
    println("✓ DetectiveAgents module imported successfully")

    # Test JuliaDB module
    using .JuliaDB
    println("✓ JuliaDB module imported successfully")

    # Test Resources module
    using .Resources
    println("✓ Resources module imported successfully")

    println("\n🎉 All modules integrated successfully!")
    println("Ghost Wallet Hunter JuliaOS consolidation complete.")

catch e
    println("❌ Error during integration test:")
    println(e)
    rethrow(e)
end
