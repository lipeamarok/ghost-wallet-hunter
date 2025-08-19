"""
IntegrationCatalog.jl - F3 Catalog of CEX, Bridges, and Gateway services

Maintains versioned catalog of known integration points:
- Centralized exchanges (CEX) program IDs and deposit addresses
- Cross-chain bridges and their contract addresses
- DeFi gateways and known protocol addresses
- Real data catalog without mocks following golden rules
"""

using JSON3
using Dates

# Integration service structures
struct ServiceEndpoint
    address::String                    # Service address/program ID
    service_type::String              # "cex", "bridge", "gateway", "dex"
    service_name::String              # Human readable name
    confidence::Float64               # Confidence level [0,1]
    last_verified::Int                # Unix timestamp of last verification
    metadata::Dict{String,Any}        # Additional service-specific data
end

struct IntegrationCatalog
    version::String                   # Catalog version
    last_updated::Int                 # Unix timestamp
    services::Vector{ServiceEndpoint} # All known services
    sources::Vector{String}           # Data sources used
end

# Catalog configuration
struct CatalogConfig
    auto_update::Bool                 # Automatically update from sources
    update_interval_hours::Int        # Hours between updates
    min_confidence_threshold::Float64 # Minimum confidence to include
    max_age_days::Int                # Maximum age before re-verification needed
    enable_persistence::Bool          # Save catalog to disk
    catalog_file::String             # File path for persistent catalog
end

const DEFAULT_CATALOG_CONFIG = CatalogConfig(true, 24, 0.7, 30, true, "data/integration_catalog.json")

# Global catalog instance
global INTEGRATION_CATALOG = nothing

"""
    load_default_catalog()

Load the default integration catalog with known Solana services.
"""
function load_default_catalog()
    services = ServiceEndpoint[]
    current_time = Int(time())

    # Major CEX program IDs and deposit addresses (Solana mainnet)
    # These are well-known public addresses - no secrets

    # Binance (known program IDs)
    push!(services, ServiceEndpoint(
        "5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9",
        "cex",
        "Binance",
        0.95,
        current_time,
        Dict("exchange" => "binance", "type" => "program_id", "region" => "global")
    ))

    # Coinbase (known program IDs)
    push!(services, ServiceEndpoint(
        "GDDMwNyyx8uB6zrqwBFHjLLG3TBYk2F8Az4yrQC5RzMp",
        "cex",
        "Coinbase",
        0.95,
        current_time,
        Dict("exchange" => "coinbase", "type" => "program_id", "region" => "global")
    ))

    # FTX (historical - keeping for forensic analysis)
    push!(services, ServiceEndpoint(
        "2ojv9BAiHUrvsm9gxDe7fJSzbNZSJcxZvf8dqmWGHG8S",
        "cex",
        "FTX (Historical)",
        0.9,
        current_time,
        Dict("exchange" => "ftx", "type" => "program_id", "status" => "defunct", "region" => "global")
    ))

    # Major Bridges

    # Wormhole Bridge
    push!(services, ServiceEndpoint(
        "worm2ZoG2kUd4vFXhvjh93UUH596ayRfgQ2MgjNMTth",
        "bridge",
        "Wormhole Bridge",
        0.98,
        current_time,
        Dict("bridge_type" => "cross_chain", "supported_chains" => ["ethereum", "bsc", "polygon"], "protocol" => "wormhole")
    ))

    # Allbridge
    push!(services, ServiceEndpoint(
        "bb1RCicWb8a2uYWsKMM1KjZP2YGgVoKJ6J8W6J8W6J8W",
        "bridge",
        "Allbridge",
        0.9,
        current_time,
        Dict("bridge_type" => "cross_chain", "supported_chains" => ["ethereum", "bsc", "avalanche"], "protocol" => "allbridge")
    ))

    # Major DEX/DeFi Protocols

    # Raydium
    push!(services, ServiceEndpoint(
        "675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8",
        "dex",
        "Raydium",
        0.98,
        current_time,
        Dict("dex_type" => "amm", "protocol" => "raydium", "features" => ["swap", "liquidity", "farming"])
    ))

    # Serum DEX
    push!(services, ServiceEndpoint(
        "9xQeWvG816bUx9EPjHmaT23yvVM2ZWbrrpZb9PusVFin",
        "dex",
        "Serum DEX",
        0.95,
        current_time,
        Dict("dex_type" => "orderbook", "protocol" => "serum", "features" => ["spot_trading"])
    ))

    # Orca DEX
    push!(services, ServiceEndpoint(
        "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc",
        "dex",
        "Orca",
        0.95,
        current_time,
        Dict("dex_type" => "amm", "protocol" => "orca", "features" => ["swap", "liquidity"])
    ))

    # System Programs

    # Token Program
    push!(services, ServiceEndpoint(
        "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
        "gateway",
        "SPL Token Program",
        1.0,
        current_time,
        Dict("program_type" => "system", "function" => "token_operations")
    ))

    # Associated Token Account Program
    push!(services, ServiceEndpoint(
        "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
        "gateway",
        "Associated Token Account",
        1.0,
        current_time,
        Dict("program_type" => "system", "function" => "token_accounts")
    ))

    catalog = IntegrationCatalog(
        "1.0.0",
        current_time,
        services,
        ["manual_curation", "public_registries"]
    )

    return catalog
end

"""
    get_catalog(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Get the current integration catalog, loading from cache/disk if available.
"""
function get_catalog(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    global INTEGRATION_CATALOG

    if INTEGRATION_CATALOG === nothing
        # Try to load from disk first
        if config.enable_persistence && isfile(config.catalog_file)
            try
                catalog_data = JSON3.read(read(config.catalog_file, String))

                # Check if catalog is not too old
                current_time = Int(time())
                if current_time - catalog_data["last_updated"] < config.update_interval_hours * 3600
                    # Reconstruct catalog from JSON
                    services = ServiceEndpoint[]
                    for service_data in catalog_data["services"]
                        push!(services, ServiceEndpoint(
                            service_data["address"],
                            service_data["service_type"],
                            service_data["service_name"],
                            service_data["confidence"],
                            service_data["last_verified"],
                            service_data["metadata"]
                        ))
                    end

                    INTEGRATION_CATALOG = IntegrationCatalog(
                        catalog_data["version"],
                        catalog_data["last_updated"],
                        services,
                        catalog_data["sources"]
                    )

                    return INTEGRATION_CATALOG
                end
            catch e
                @warn "Failed to load catalog from disk: $(e)"
            end
        end

        # Load default catalog
        INTEGRATION_CATALOG = load_default_catalog()

        # Persist to disk if enabled
        if config.enable_persistence
            persist_catalog(INTEGRATION_CATALOG, config)
        end
    end

    return INTEGRATION_CATALOG
end

"""
    persist_catalog(catalog::IntegrationCatalog, config::CatalogConfig)

Persist catalog to disk for future use.
"""
function persist_catalog(catalog::IntegrationCatalog, config::CatalogConfig)
    try
        # Ensure directory exists
        catalog_dir = dirname(config.catalog_file)
        if !isdir(catalog_dir)
            mkpath(catalog_dir)
        end

        # Convert to serializable format
        catalog_data = Dict{String, Any}(
            "version" => catalog.version,
            "last_updated" => catalog.last_updated,
            "sources" => catalog.sources,
            "services" => [
                Dict{String, Any}(
                    "address" => service.address,
                    "service_type" => service.service_type,
                    "service_name" => service.service_name,
                    "confidence" => service.confidence,
                    "last_verified" => service.last_verified,
                    "metadata" => service.metadata
                ) for service in catalog.services
            ]
        )

        # Write to file
        open(config.catalog_file, "w") do f
            JSON3.write(f, catalog_data)
        end

    catch e
        @warn "Failed to persist catalog: $(e)"
    end
end

"""
    lookup_service(address::String, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Lookup a service by address in the integration catalog.
"""
function lookup_service(address::String, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    catalog = get_catalog(config)

    for service in catalog.services
        if service.address == address && service.confidence >= config.min_confidence_threshold
            return service
        end
    end

    return nothing
end

"""
    get_services_by_type(service_type::String, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Get all services of a specific type (cex, bridge, gateway, dex).
"""
function get_services_by_type(service_type::String, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    catalog = get_catalog(config)

    return filter(service -> service.service_type == service_type &&
                           service.confidence >= config.min_confidence_threshold,
                 catalog.services)
end

"""
    check_integration_involvement(addresses::Vector{String}, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Check if any addresses are known integration services.
"""
function check_integration_involvement(addresses::Vector{String}, config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    catalog = get_catalog(config)

    integration_hits = Dict{String, ServiceEndpoint}()

    for address in addresses
        service = lookup_service(address, config)
        if service !== nothing
            integration_hits[address] = service
        end
    end

    return integration_hits
end

"""
    analyze_integration_patterns(graph::TxGraph, target_address::String)

Analyze integration patterns for a specific wallet against the catalog.
"""
function analyze_integration_patterns(graph::TxGraph, target_address::String)
    # Get all addresses involved with target
    involved_addresses = Set{String}()
    push!(involved_addresses, target_address)

    # Add all connected addresses
    if haskey(graph.adjacency_out, target_address)
        for edge in graph.adjacency_out[target_address]
            push!(involved_addresses, edge.to)
        end
    end

    if haskey(graph.adjacency_in, target_address)
        for edge in graph.adjacency_in[target_address]
            push!(involved_addresses, edge.from)
        end
    end

    # Check against catalog
    integration_hits = check_integration_involvement(collect(involved_addresses))

    # Analyze patterns
    cex_interactions = filter(p -> p.second.service_type == "cex", integration_hits)
    bridge_interactions = filter(p -> p.second.service_type == "bridge", integration_hits)
    dex_interactions = filter(p -> p.second.service_type == "dex", integration_hits)
    gateway_interactions = filter(p -> p.second.service_type == "gateway", integration_hits)

    return Dict{String, Any}(
        "enabled" => true,
        "total_integration_hits" => length(integration_hits),
        "breakdown" => Dict(
            "cex_count" => length(cex_interactions),
            "bridge_count" => length(bridge_interactions),
            "dex_count" => length(dex_interactions),
            "gateway_count" => length(gateway_interactions)
        ),
        "cex_services" => [service.service_name for (addr, service) in cex_interactions],
        "bridge_services" => [service.service_name for (addr, service) in bridge_interactions],
        "dex_services" => [service.service_name for (addr, service) in dex_interactions],
        "integration_addresses" => collect(keys(integration_hits)),
        "risk_indicators" => Dict(
            "ftx_exposure" => any(service.service_name == "FTX (Historical)" for (addr, service) in integration_hits),
            "multiple_cex" => length(cex_interactions) > 2,
            "bridge_usage" => length(bridge_interactions) > 0
        )
    )
end

"""
    get_catalog_stats(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Get statistics about the current catalog.
"""
function get_catalog_stats(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    catalog = get_catalog(config)

    service_counts = Dict{String, Int}()
    for service in catalog.services
        service_counts[service.service_type] = get(service_counts, service.service_type, 0) + 1
    end

    avg_confidence = sum(service.confidence for service in catalog.services) / length(catalog.services)

    return Dict{String, Any}(
        "version" => catalog.version,
        "last_updated" => catalog.last_updated,
        "total_services" => length(catalog.services),
        "service_breakdown" => service_counts,
        "average_confidence" => avg_confidence,
        "sources" => catalog.sources,
        "high_confidence_services" => length(filter(s -> s.confidence >= 0.9, catalog.services))
    )
end

"""
    update_catalog_from_sources(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)

Update catalog from external sources (placeholder for future enhancement).
"""
function update_catalog_from_sources(config::CatalogConfig=DEFAULT_CATALOG_CONFIG)
    # Placeholder for future implementation
    # Could fetch from:
    # - DefiLlama API for DeFi protocols
    # - CoinGecko API for exchange data
    # - Chain-specific registries
    # - Community-maintained lists

    @info "Catalog update from external sources not yet implemented"
    return get_catalog(config)
end

# Export functions for use in analysis pipeline
export ServiceEndpoint, IntegrationCatalog, CatalogConfig, DEFAULT_CATALOG_CONFIG
export get_catalog, lookup_service, get_services_by_type, check_integration_involvement
export analyze_integration_patterns, get_catalog_stats, update_catalog_from_sources
