# 🧪 Quick Test Validation Script
# Propósito: Validar rapidamente a infraestrutura implementada

using Dates

# Include our test utilities
include("utils/test_helpers.jl")

println("🚀 Ghost Wallet Hunter - Quick Validation Test")
println("Timestamp: $(now())")
println()

try
    # Test 1: Wallet database
    println("📋 Test 1: Validating wallet database...")
    wallet_stats = get_wallet_stats()
    println("✅ Wallet database loaded: $(wallet_stats["total_wallets"]) wallets")
    println("   - CEX wallets: $(wallet_stats["cex_wallets"])")
    println("   - DeFi wallets: $(wallet_stats["defi_wallets"])")
    println("   - Native programs: $(wallet_stats["native_programs"])")
    println()

    # Test 2: Address validation
    println("🔍 Test 2: Address validation...")
    test_addresses = [
        "So11111111111111111111111111111111111111112",  # Valid
        "invalid_address"  # Invalid
    ]

    for addr in test_addresses
        result = validate_solana_address(addr)
        status = result ? "✅ Valid" : "❌ Invalid"
        println("   $status: $(addr[1:min(16, length(addr))])")
    end
    println()

    # Test 3: RPC connectivity
    println("🌐 Test 3: RPC connectivity...")
    rpc_result = test_rpc_connection()

    if rpc_result["success"]
        println("✅ RPC connection successful!")
        println("   Response time: $(round(rpc_result["response_time"], digits=2))s")
        println("   Health status: $(rpc_result["health_status"])")
    else
        println("❌ RPC connection failed: $(rpc_result["error"])")
    end
    println()

    # Test 4: Real wallet data
    println("📊 Test 4: Real wallet data retrieval...")
    wrapped_sol = "So11111111111111111111111111111111111111112"

    account_info = get_account_info(wrapped_sol)
    if account_info["success"]
        println("✅ Account info retrieved for Wrapped SOL")
    else
        println("❌ Failed to get account info: $(account_info["error"])")
    end

    balance_info = get_sol_balance("9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM")
    if balance_info["success"]
        println("✅ Balance retrieved for Binance wallet: $(balance_info["balance_sol"]) SOL")
    else
        println("❌ Failed to get balance: $(balance_info["error"])")
    end
    println()

    println("🎉 All validation tests completed!")
    println("📁 Test infrastructure is ready for comprehensive testing.")

catch e
    println("❌ Validation failed with error:")
    println(e)
end
