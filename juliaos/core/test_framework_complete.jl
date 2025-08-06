#!/usr/bin/env julia

println("🚀 Testing Complete Framework with All Fixes")
println("=============================================")

println("📦 Loading JuliaOSFramework...")
try
    include("src/framework/JuliaOSFramework.jl")
    using .JuliaOSFramework
    println("✅ Framework loaded successfully")

    println("🔧 Testing framework initialization...")
    try
        result = initialize()
        println("✅ Framework initialized: $result")
    catch e
        println("⚠️ Framework initialization warning: $(typeof(e))")
        println("Details: $e")
    end

    println("🕵️ Testing detective creation...")
    detectives = ["poirot", "marple", "spade"]
    for detective in detectives
        try
            agent = create_detective_agent(detective)
            if agent !== nothing
                println("✅ Created detective: $detective")
            else
                println("⚠️ Detective creation returned null: $detective")
            end
        catch e
            println("❌ Failed to create detective $detective: $(typeof(e))")
        end
    end

    println("🩺 Testing system health...")
    try
        health = get_system_health()
        println("✅ System health: $health")
    catch e
        println("⚠️ Health check issue: $(typeof(e))")
    end

    println("📊 Testing performance metrics...")
    try
        metrics = get_performance_metrics()
        println("✅ Metrics retrieved: $(metrics !== nothing)")
    catch e
        println("⚠️ Metrics issue: $(typeof(e))")
    end

    println("🎉 Complete framework test finished!")

catch e
    println("❌ Framework loading failed: $(typeof(e))")
    println("Error: $e")
    if isa(e, LoadError)
        println("Load error details: $(e.error)")
    end
end

println("🏁 Complete framework test completed")
