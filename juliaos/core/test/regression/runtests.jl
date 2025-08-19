using Test
for f in [
    "test_known_wallets.jl",
    "test_risk_consistency.jl",
    "test_backwards_compat.jl"
]
    include(f)
end
