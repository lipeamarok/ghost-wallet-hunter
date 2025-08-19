"""
TxParser.jl - Real transaction parser for graph construction (F1_parser)

Parses actual Solana transaction data into graph structures.
NO MOCKS - works with real transaction JSON from RPC calls.
"""

# TxTypes are included by the parent Analysis module; no local includes/usings needed

"""
Parse a single transaction into TxEdge structures.
Extracts real account interactions and balance changes.
"""
function parse_transaction(tx::Dict, wallet_address::String)::Vector{TxEdge}
    edges = TxEdge[]

    try
        # Extract basic transaction info
        signature = ""
        if haskey(tx, "_signature")
            signature = String(tx["_signature"])
        elseif haskey(tx, "transaction") && haskey(tx["transaction"], "signatures") && length(tx["transaction"]["signatures"]) > 0
            signature = String(tx["transaction"]["signatures"][1])
        end

        slot = get(tx, "slot", nothing)
        block_time = get(tx, "blockTime", nothing)

        # Parse account interactions from transaction structure
        if haskey(tx, "transaction") && haskey(tx["transaction"], "message")
            message = tx["transaction"]["message"]

            if haskey(message, "accountKeys") && haskey(tx, "meta")
                accounts = message["accountKeys"]
                meta = tx["meta"]

                # Extract balance changes for SOL transfers
                if haskey(meta, "preBalances") && haskey(meta, "postBalances")
                    pre_balances = meta["preBalances"]
                    post_balances = meta["postBalances"]

                    # Find wallet index
                    wallet_idx = findfirst(acc -> String(acc) == wallet_address, accounts)

                    if wallet_idx !== nothing && length(pre_balances) == length(accounts)
                        wallet_pre = Float64(pre_balances[wallet_idx]) / 1e9  # Convert lamports to SOL
                        wallet_post = Float64(post_balances[wallet_idx]) / 1e9
                        wallet_delta = wallet_post - wallet_pre

                        # Find counterparty with opposite balance change
                        for (i, acc) in enumerate(accounts)
                            if i == wallet_idx; continue; end
                            if i <= length(pre_balances) && i <= length(post_balances)
                                acc_pre = Float64(pre_balances[i]) / 1e9
                                acc_post = Float64(post_balances[i]) / 1e9
                                acc_delta = acc_post - acc_pre

                                # If significant opposite balance change, it's likely a transfer
                                if abs(acc_delta) > 0.001 && abs(wallet_delta) > 0.001
                                    if wallet_delta > 0 && acc_delta < 0
                                        # Wallet received, counterparty sent
                                        edge = TxEdge(
                                            String(acc),
                                            wallet_address,
                                            abs(wallet_delta),
                                            slot,
                                            block_time,
                                            "system_program",  # Default for SOL transfers
                                            signature,
                                            "in"
                                        )
                                        push!(edges, edge)
                                    elseif wallet_delta < 0 && acc_delta > 0
                                        # Wallet sent, counterparty received
                                        edge = TxEdge(
                                            wallet_address,
                                            String(acc),
                                            abs(wallet_delta),
                                            slot,
                                            block_time,
                                            "system_program",
                                            signature,
                                            "out"
                                        )
                                        push!(edges, edge)
                                    end
                                end
                            end
                        end
                    end
                end

                # Parse instructions for program interactions
                if haskey(message, "instructions")
                    for instruction in message["instructions"]
                        if haskey(instruction, "programIdIndex") && haskey(instruction, "accounts")
                            program_idx = instruction["programIdIndex"] + 1  # Julia 1-indexed
                            if program_idx <= length(accounts)
                                program_id = String(accounts[program_idx])

                                # Track program interactions as edges
                                for acc_idx in instruction["accounts"]
                                    acc_idx_1 = acc_idx + 1  # Convert to 1-indexed
                                    if acc_idx_1 <= length(accounts)
                                        account = String(accounts[acc_idx_1])
                                        if account == wallet_address
                                            # Create program interaction edge
                                            edge = TxEdge(
                                                wallet_address,
                                                program_id,
                                                0.0,  # Program interactions don't transfer SOL directly
                                                slot,
                                                block_time,
                                                program_id,
                                                signature,
                                                "program_interaction"
                                            )
                                            push!(edges, edge)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    catch e
        # Don't fail entire parsing for one bad transaction
        @warn "Failed to parse transaction" error=e signature=get(tx, "_signature", "unknown")
    end

    return edges
end

"""
Parse multiple transactions into a complete transaction set.
Real transaction processing - no mocking.
"""
function parse_transactions(transactions::Vector, wallet_address::String)::Vector{TxEdge}
    all_edges = TxEdge[]

    for tx in transactions
        edges = parse_transaction(tx, wallet_address)
        append!(all_edges, edges)
    end

    return all_edges
end

"""
Validate parsed transaction data quality.
Ensures we have real, meaningful transaction data.
"""
function validate_parsed_data(edges::Vector{TxEdge})::Dict{String,Any}
    if isempty(edges)
        return Dict(
            "valid" => false,
            "reason" => "no_transactions_parsed",
            "edge_count" => 0
        )
    end

    # Count different types of edges
    sol_transfers = count(e -> e.value > 0, edges)
    program_interactions = count(e -> e.direction == "program_interaction", edges)
    with_timestamps = count(e -> e.block_time !== nothing, edges)

    return Dict(
        "valid" => true,
        "edge_count" => length(edges),
        "sol_transfers" => sol_transfers,
        "program_interactions" => program_interactions,
        "timestamp_coverage" => with_timestamps / length(edges),
        "quality_score" => min(1.0, (sol_transfers + program_interactions) / max(1, length(edges)))
    )
end

export parse_transaction, parse_transactions, validate_parsed_data
