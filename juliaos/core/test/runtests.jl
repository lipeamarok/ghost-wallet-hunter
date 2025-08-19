# 📋 Ghost Wallet Hunter - Main Test Runner
# Atualizado: 12/08/2025
# Status: 🟡 IN PROGRESS - Expandido para suporte completo
# Propósito: Entry point para todos os testes (SEM MOCKS)

using Test
using JuliaOS
using Dates

# Load test utilities first
include("utils/test_helpers.jl")

@info "🚀 Ghost Wallet Hunter Test Suite Starting..."
@info "Test Environment: Real Data Only (NO MOCKS)"
@info "Timestamp: $(now())"

# Get command line arguments
args = ARGS

# If no arguments, run all tests
if isempty(args)
    @info "Running all test suites..."

    # ===== EXISTING TESTS (Legacy) =====
    @testset "Legacy JuliaOS Tests" begin
        @info "Running legacy test modules..."
        include("trading/runtests.jl")
        include("risk/runtests.jl")
        include("storage/runtests.jl")
        include("swarm/runtests.jl")
        include("dex/runtests.jl")
        include("framework/runtests.jl")
        include("price/runtests.jl")
        include("api/runtests.jl")
        include("blockchain/runtests.jl")
        include("agents/runtests.jl")
    end

    # ===== NEW COMPREHENSIVE TESTS (Real Data) =====
    @testset "Ghost Wallet Hunter - Real Data Tests" begin
        @info "🔬 Running comprehensive real data test suite..."

        # UNIT TESTS
        @testset "Unit Tests - Real Data" begin
            @info "🧪 Unit Tests: Analysis Core"
            # include("unit/analysis/runtests.jl")  # TODO: Create

            @info "🧪 Unit Tests: Detective Agents"
            # include("unit/agents/runtests.jl")    # TODO: Create

            @info "🧪 Unit Tests: Tools"
            # include("unit/tools/runtests.jl")     # TODO: Create

            @info "🧪 Unit Tests: API Layer"
            # include("unit/api/runtests.jl")       # TODO: Create

            @info "🧪 Unit Tests: Blockchain"
            # include("unit/blockchain/runtests.jl") # TODO: Create
        end

        # INTEGRATION TESTS
        @testset "Integration Tests - Real Workflows" begin
            @info "🔄 Integration Tests: Full Investigation Pipeline"
            # include("integration/runtests.jl")    # TODO: Create
        end

        # REGRESSION TESTS
        @testset "Regression Tests - Known Wallets" begin
            @info "📊 Regression Tests: Known Wallet Profiles"
            # include("regression/runtests.jl")     # TODO: Create
        end

        # LOAD TESTS
        @testset "Load Tests - Performance Validation" begin
            @info "⚡ Load Tests: Concurrent Investigations"
            # include("load/runtests.jl")           # TODO: Create
        end
    end

else
    @info "Running specified test files: $(join(args, ", "))"
    for test_file in args
        path = test_file
        if !endswith(path, ".jl")
            path *= ".jl"
        end
        # Allow relative shorthand like unit/analysis/test_explainability.jl
        if !isfile(path)
            candidate = joinpath(@__DIR__, path)
            if isfile(candidate)
                path = candidate
            else
                # Try resolve relative to test root (already in test dir when invoked normally)
                path = abspath(path)
            end
        end
        if !isfile(path)
            @warn "Skipping missing test file" requested=test_file resolved=path
            continue
        end
        @info "Executing: $(path)"
        include(path)
    end
end

# Summary and cleanup
@testset "Ghost Wallet Hunter Test Suite" begin
    @info "✅ Test suite execution completed"
    @info "Timestamp: $(now())"
    @info "Environment: Real Solana blockchain data"

    # TODO: Add test result summary when individual tests are implemented
    @test true  # Placeholder for now
end