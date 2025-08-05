#!/usr/bin/env julia

println("=== Testing JuliaOS Module Loading ===")

try
    println("1. Including main JuliaOS module...")
    include("src/JuliaOS.jl")
    println("✓ JuliaOS module loaded successfully!")

    println("2. Testing if we can import JuliaOS...")
    using .JuliaOS
    println("✓ JuliaOS imported successfully!")

    println("3. Testing Ghost Wallet Hunter detectives...")
    include("src/agents/DetectiveAgents.jl")
    println("✓ DetectiveAgents module loaded successfully!")

    println("4. Testing Ghost Server...")
    include("src/ghost_server.jl")
    println("✓ Ghost Server loaded successfully!")

    println("\n=== All tests passed! The consolidated structure is working! ===")

catch e
    println("❌ Error occurred: ", e)
    println("\nStacktrace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
