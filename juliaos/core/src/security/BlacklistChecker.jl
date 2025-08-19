"""
BlacklistChecker.jl - High-performance wallet blacklist checking service

Migrated from backend/services/blacklist_checker.py for native Julia performance.
This service fetches, caches, and checks wallet addresses against multiple public scam lists.
"""
module BlacklistChecker
export compact_blacklist_entry, check_address_compact

using HTTP
using JSON3
using Dates
using Logging

# ----------------------------------------
# Optional on-disk cache configuration
# ----------------------------------------
const BLACKLIST_CACHE_ENABLED = get(ENV, "JULIAOS_BLACKLIST_CACHE_ENABLE", "1") in ("1","true","yes","on")
const BLACKLIST_CACHE_TTL_S = try parse(Int, get(ENV, "JULIAOS_BLACKLIST_CACHE_TTL", "3600")) catch; 3600 end
const BLACKLIST_CACHE_PATH = begin
    base = get(ENV, "JULIAOS_BLACKLIST_CACHE_FILE", joinpath(@__DIR__, "..", "..", "data", "blacklist_cache.json"))
    abspath(base)
end

export check_address, check_address_compact, initialize_blacklist, get_stats
# NEW exports
export update_blacklists!, get_sources
export _PRIME_FROM_CACHE! # internal fast path for main.jl (not public API commitment)

# Map of address -> set of sources that flagged it
const ADDR_SOURCE_MAP = Dict{String, Set{String}}()

# Allow disabling sources via env (e.g., "off", "none")
const OFF_STRINGS = Set(["off", "none", "disable", "disabled", "false", "0"])

# Configurable fetch timeout (seconds)
const BLACKLIST_FETCH_TIMEOUT_S = let v = tryparse(Int, get(ENV, "BLACKLIST_FETCH_TIMEOUT_S", "12")); isnothing(v) ? 12 : max(3, v) end

# ========================================
# DATA STRUCTURES & STATE
# ========================================

# Configurable source URL lists (env override, else sensible candidates)
const SOLANA_URLS_DEFAULT = begin
    env = get(ENV, "BLACKLIST_SOLANA_URLS", "")
    s = lowercase(strip(env))
    if !isempty(env) && (s in OFF_STRINGS)
        String[]
    else
        urls = [strip(u) for u in split(env, ",") if !isempty(strip(u))]
        isempty(urls) ? [
            # Tokenlist candidates (tokens tagged with "scam")
            "https://raw.githubusercontent.com/solana-labs/token-list/main/src/tokens/solana.tokenlist.json",
            "https://raw.githubusercontent.com/solana-labs/token-list/master/src/tokens/solana.tokenlist.json",
            "https://raw.githubusercontent.com/solana-foundation/token-list/main/src/tokens/solana.tokenlist.json",
        ] : urls
    end
end

const CHAINABUSE_URLS_DEFAULT = begin
    env = get(ENV, "BLACKLIST_CHAINABUSE_URLS", "")
    s = lowercase(strip(env))
    if !isempty(env) && (s in OFF_STRINGS)
        String[]
    else
        urls = [strip(u) for u in split(env, ",") if !isempty(strip(u))]
        isempty(urls) ? [
            # CryptoScamDB candidates for Solana addresses
            "https://raw.githubusercontent.com/cryptoscamdb/blacklist/master/data/solana.json",
            "https://raw.githubusercontent.com/cryptoscamdb/blacklist/main/data/solana.json",
            "https://raw.githubusercontent.com/cryptoscamdb/blacklist/master/solana.json",
        ] : urls
    end
end

# NEW: Extra community sources (JSON/CSV); user-provided
const EXTRA_URLS_DEFAULT = begin
    env = get(ENV, "BLACKLIST_EXTRA_URLS", "")
    s = lowercase(strip(env))
    if !isempty(env) && (s in OFF_STRINGS)
        String[]
    else
        [strip(u) for u in split(env, ",") if !isempty(strip(u))]
    end
end

mutable struct BlacklistState
    scam_addresses::Set{String}
    last_update::Union{DateTime, Nothing}
    update_interval_seconds::Int
    lock::ReentrantLock
end

# Global state for the service (store addresses lowercased)
const STATE = BlacklistState(Set{String}(), nothing, 300, ReentrantLock())

# Track per-source status: ok | failed | disabled | unknown
const LAST_SOURCE_STATUS = Dict{String, String}()
# Prevent concurrent background updates
const IS_UPDATING = Base.RefValue(false)

# ----------------------------------------
# Helpers
# ----------------------------------------

# Validate Solana base58 address (32-44 chars, no 0 O I l)
const SOLANA_ADDR_RE = r"^[1-9A-HJ-NP-Za-km-z]{32,44}$"

is_valid_solana_address(s::AbstractString) = occursin(SOLANA_ADDR_RE, String(s))

# Extract addresses from CSV-like text
function _parse_csv_addresses(txt::String)::Set{String}
    addrs = Set{String}()
    # Use Julia regex literal r"..." instead of /.../
    lines = split(txt, r"\r?\n")
    isempty(lines) && return addrs
    # detect delimiter by first non-empty line (guard when all lines are empty)
    nonempty = filter(l -> !isempty(strip(l)), lines)
    isempty(nonempty) && return addrs
    header = first(nonempty)
    delim = occursin(";", header) ? ';' : ','
    cols = split(header, delim)
    # find column index containing address (case-insensitive)
    idx = findfirst(i -> begin
            col = lowercase(strip(cols[i]))
            occursin("address", col) || occursin("wallet", col) || occursin("account", col)
        end, eachindex(cols))
    for (n, line) in enumerate(lines)
        if n == 1 && idx !== nothing
            continue
        end
        parts = split(line, delim)
        if idx !== nothing && idx <= length(parts)
            val = strip(parts[idx])
            if !isempty(val) && is_valid_solana_address(val)
                push!(addrs, lowercase(val))
            end
        else
            # fallback: take first token if looks like address
            tokens = split(line)
            if !isempty(tokens)
                val = strip(first(tokens))
                if !isempty(val) && is_valid_solana_address(val)
                    push!(addrs, lowercase(val))
                end
            end
        end
    end
    return addrs
end

# Parse generic JSON formats
function _parse_generic_json(data)::Set{String}
    addrs = Set{String}()
    try
        if data isa JSON3.Array
            for entry in data
                if entry isa String
                    if is_valid_solana_address(entry)
                        push!(addrs, lowercase(String(entry)))
                    end
                elseif entry isa JSON3.Object
                    addr = get(entry, "address", get(entry, "wallet", get(entry, "account", "")))
                    if !isempty(addr) && is_valid_solana_address(String(addr))
                        push!(addrs, lowercase(String(addr)))
                    end
                end
            end
        elseif data isa JSON3.Object
            if haskey(data, "addresses")
                for v in data["addresses"]
                    if v isa String && is_valid_solana_address(v)
                        push!(addrs, lowercase(String(v)))
                    end
                end
            end
        end
    catch e
        @error "Error parsing generic JSON addresses" error=e
    end
    return addrs
end

# ========================================
# INITIALIZATION & UPDATES
# ========================================

"""
    initialize_blacklist()

Initialize the blacklist checker by fetching data from all sources.
This should be called at application startup.
"""
function initialize_blacklist()
    @info "Initializing BlacklistChecker..."
    try
        update_blacklists!()
        count = length(STATE.scam_addresses)
        @info "Blacklist initialized successfully with $count addresses."
    catch e
        @error "Failed to initialize blacklist" error=e
    end
end

"""
    update_blacklists!()

Force an update of the blacklists from all configured sources.
This function is thread-safe.
"""
function update_blacklists!()
    lock(STATE.lock) do
        @info "Updating blacklists from all sources..."

        all_addresses = Set{String}()
        tasks = Dict{String,Task}()

        empty!(LAST_SOURCE_STATUS)
        if !isempty(SOLANA_URLS_DEFAULT)
            tasks["solana_tokenlist"] = Threads.@spawn _fetch_source("solana_tokenlist", SOLANA_URLS_DEFAULT)
        else
            LAST_SOURCE_STATUS["solana_tokenlist"] = "disabled"
        end
        if !isempty(CHAINABUSE_URLS_DEFAULT)
            tasks["chainabuse_solana"] = Threads.@spawn _fetch_source("chainabuse_solana", CHAINABUSE_URLS_DEFAULT)
        else
            LAST_SOURCE_STATUS["chainabuse_solana"] = "disabled"
        end
        if !isempty(EXTRA_URLS_DEFAULT)
            tasks["extra_sources"] = Threads.@spawn _fetch_source_generic(EXTRA_URLS_DEFAULT)
        else
            LAST_SOURCE_STATUS["extra_sources"] = "disabled"
        end

        # Temporary aggregation for source mapping
        local_source_map = Dict{String, Set{String}}()

        for (name, t) in tasks
            try
                result = fetch(t)
                if result isa Set
                    union!(all_addresses, result)
                    for addr in result
                        key = lowercase(addr)
                        if !haskey(local_source_map, key)
                            local_source_map[key] = Set{String}()
                        end
                        push!(local_source_map[key], name)
                    end
                    LAST_SOURCE_STATUS[name] = "ok"
                else
                    LAST_SOURCE_STATUS[name] = "failed"
                end
            catch e
                @error "Error updating source $name" error=e
                LAST_SOURCE_STATUS[name] = "failed"
            end
        end

        if !isempty(all_addresses)
            STATE.scam_addresses = Set{String}(lowercase.(collect(all_addresses)))
            empty!(ADDR_SOURCE_MAP)
            for (addr, srcs) in local_source_map
                ADDR_SOURCE_MAP[addr] = Set{String}(srcs)
            end
            STATE.last_update = now(UTC)
            @info "Blacklist updated with $(length(STATE.scam_addresses)) addresses."
            _maybe_save_cache(; force=true)
        else
            @warn "No addresses were fetched. Blacklist might be empty or sources are down."
            STATE.last_update = now(UTC)
        end
    end
end

"""
    _fetch_source(source_name::String, urls::AbstractVector{<:AbstractString})::Set{String}

Try a list of candidate URLs for a given source; return first successful parse.
"""
function _fetch_source(source_name::String, urls::AbstractVector{<:AbstractString})::Set{String}
    for url in urls
        try
            @info "Fetching from $source_name..." url=url
            resp = HTTP.get(url; headers=Dict("User-Agent"=>"Ghost-Wallet-Hunter-Julia-Client/1.0"), timeout=BLACKLIST_FETCH_TIMEOUT_S)
            if resp.status == 200
                data = JSON3.read(resp.body)
                return source_name == "solana_tokenlist" ? _parse_solana_tokenlist(data) :
                       source_name == "chainabuse_solana" ? _parse_chainabuse(data) : Set{String}()
            else
                @warn "Fetch failed" source=source_name status=resp.status url=url
            end
        catch e
            @error "Error fetching or parsing $source_name" url=url error=e
        end
    end
    return Set{String}()
end

# ----------------------------------------
# Cache persistence helpers
# ----------------------------------------
function _maybe_save_cache(; force::Bool=false)
    BLACKLIST_CACHE_ENABLED || return
    # only save if force or file missing/expired
    if !force && isfile(BLACKLIST_CACHE_PATH)
        age = time() - stat(BLACKLIST_CACHE_PATH).mtime
        age <= BLACKLIST_CACHE_TTL_S && return
    end
    try
        mkpath(dirname(BLACKLIST_CACHE_PATH))
        open(BLACKLIST_CACHE_PATH, "w") do io
            JSON3.write(io, Dict(
                "saved_at" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS"),
                "count" => length(STATE.scam_addresses),
                "addresses" => collect(STATE.scam_addresses),
                "sources" => get_sources(),
            ))
        end
        @info "Blacklist cache saved" path=BLACKLIST_CACHE_PATH count=length(STATE.scam_addresses)
    catch e
        @warn "Failed to save blacklist cache" path=BLACKLIST_CACHE_PATH error=e
    end
end

""" _PRIME_FROM_CACHE!(addresses)::Int
Internal helper to load addresses (already lowercased) into the in-memory set
without triggering network fetch. Returns number of new addresses added.
"""
function _PRIME_FROM_CACHE!(addresses)::Int
    lock(STATE.lock) do
        before = length(STATE.scam_addresses)
        for a in addresses
            push!(STATE.scam_addresses, lowercase(String(a)))
        end
        STATE.last_update = now(UTC)
        added = length(STATE.scam_addresses) - before
        @info "Blacklist primed from cache" added=added total=length(STATE.scam_addresses)
        return added
    end
end

# NEW: Generic fetcher for extra sources (auto-detect JSON/CSV)
function _fetch_source_generic(urls::AbstractVector{<:AbstractString})::Set{String}
    collected = Set{String}()
    for url in urls
        try
            @info "Fetching from extra_sources..." url=url
            resp = HTTP.get(url; headers=Dict("User-Agent"=>"Ghost-Wallet-Hunter-Julia-Client/1.0"), timeout=BLACKLIST_FETCH_TIMEOUT_S)
            if resp.status != 200
                @warn "Fetch failed" source="extra_sources" status=resp.status url=url
                continue
            end
            body = String(resp.body)
            content_type = lowercase(String(get(HTTP.header(resp, "Content-Type"), "")))
            if startswith(strip(body), "[") || startswith(strip(body), "{") || occursin("json", content_type)
                data = JSON3.read(body)
                union!(collected, _parse_generic_json(data))
            else
                union!(collected, _parse_csv_addresses(body))
            end
        catch e
            @error "Error fetching or parsing extra source" url=url error=e
        end
    end
    return collected
end

# ========================================
# PARSERS
# ========================================

# Parse Solana tokenlist format collecting tokens tagged with "scam"
function _parse_solana_tokenlist(data)::Set{String}
    addresses = Set{String}()
    try
        # tokenlist has a top-level key "tokens" (array of objects)
        tokens = nothing
        if data isa JSON3.Object
            tokens = get(data, "tokens", nothing)
        elseif data isa JSON3.Array
            tokens = data
        end
        if tokens !== nothing && tokens isa JSON3.Array
            for entry in tokens
                try
                    # Accept entries with tags containing "scam"
                    tags = String[]
                    if entry isa JSON3.Object && haskey(entry, "tags")
                        t = entry["tags"]
                        if t isa JSON3.Array
                            tags = [lowercase(String(x)) for x in t]
                        elseif t isa String
                            tags = [lowercase(String(t))]
                        end
                    end
                    if any(tag -> occursin("scam", tag), tags)
                        if haskey(entry, "address")
                            addr = String(entry["address"])
                            if is_valid_solana_address(addr)
                                push!(addresses, lowercase(addr))
                            end
                        end
                    end
                catch; end
            end
        end
    catch e
        @error "Error parsing Solana tokenlist data" error=e
    end
    return addresses
end

function _parse_chainabuse(data)::Set{String}
    addresses = Set{String}()
    try
        if data isa JSON3.Array
            for entry in data
                addr = ""
                if entry isa JSON3.Object
                    addr = get(entry, "address", get(entry, "wallet", get(entry, "account", "")))
                elseif entry isa String
                    addr = entry
                end
                if !isempty(addr) && is_valid_solana_address(String(addr))
                    push!(addresses, lowercase(String(addr)))
                end
            end
        elseif data isa JSON3.Object && haskey(data, "addresses")
            for addr in data["addresses"]
                if addr isa String && is_valid_solana_address(addr)
                    push!(addresses, lowercase(String(addr)))
                end
            end
        end
    catch e
        @error "Error parsing Chainabuse data" error=e
    end
    return addresses
end

# ========================================
# PUBLIC API
# ========================================

# NEW: Expose configured sources
function get_sources()::Dict
    return Dict(
        "solana_tokenlist" => SOLANA_URLS_DEFAULT,
        "chainabuse_solana" => CHAINABUSE_URLS_DEFAULT,
        "extra_sources" => EXTRA_URLS_DEFAULT,
        "fetch_timeout_seconds" => BLACKLIST_FETCH_TIMEOUT_S,
    )
end

"""
    check_address(address::String)::Dict

Check if a single wallet address is in the blacklist.
Triggers an automatic update if the cache is stale.
"""
function check_address(address::String)::Dict
    if _should_update() && !IS_UPDATING[]
        @info "Blacklist is stale, triggering update..."
        IS_UPDATING[] = true
        # Refresh in background, do not block; ensure flag reset
        Threads.@spawn begin
            try
                update_blacklists!()
            catch e
                @error "Background blacklist update failed" error=e
            finally
                IS_UPDATING[] = false
            end
        end
    end

    key = lowercase(address)
    is_blacklisted = key in STATE.scam_addresses
    hits = haskey(ADDR_SOURCE_MAP, key) ? collect(ADDR_SOURCE_MAP[key]) : String[]

    # Build truthful source reporting
    all_names = ["solana_tokenlist", "chainabuse_solana", "extra_sources"]
    sources_used = String[]
    sources_failed = String[]
    sources_disabled = String[]
    for name in all_names
        st = get(LAST_SOURCE_STATUS, name, "unknown")
        if st == "ok"
            push!(sources_used, name)
        elseif st == "failed"
            push!(sources_failed, name)
        elseif st == "disabled"
            push!(sources_disabled, name)
        end
    end

    reason = if !is_blacklisted
        "Not found in public blacklists"
    elseif any(==("solana_tokenlist"), hits)
        "Token tagged as scam in Solana token list"
    elseif any(==("chainabuse_solana"), hits)
        "Reported by CryptoScamDB/Chainabuse"
    elseif any(==("extra_sources"), hits)
        "Listed in community-provided extra sources"
    else
        "Flagged by public blacklist sources"
    end

    result = Dict(
        "address" => address,
        "is_blacklisted" => is_blacklisted,
        "threat_level" => is_blacklisted ? "HIGH" : "CLEAN",
        # ISO 8601 with Z suffix for UTC
        "last_checked" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"),
        "sources_used" => sources_used,
        "sources_failed" => sources_failed,
        "sources_disabled" => sources_disabled,
        "source_hits" => hits,
        "reason" => reason,
    )
    # Backward compatibility: expose sources_checked as alias of sources_used
    result["sources_checked"] = sources_used

    if is_blacklisted
        result["warning"] = "ALERT: Address $(address) is on a public scam/fraud blacklist!"
        result["recommendation"] = "Maximum caution is advised. Avoid transactions with this address."
    end

    return result
end

"""
    compact_blacklist_entry(full::Dict) -> Dict

Top-level adapter (previously nested) returning a reduced, stable shape.
Guaranteed keys: address, is_blacklisted, risk_score, sources, updated_at, reason
"""
function compact_blacklist_entry(full::Dict)
    return Dict(
        "address" => get(full, "address", missing),
        "is_blacklisted" => get(full, "is_blacklisted", false),
        "risk_score" => get(full, "is_blacklisted", false) ? 0.9 : 0.1,
        "sources" => get(full, "source_hits", get(full, "sources_used", String[])),
        "updated_at" => get(full, "last_checked", Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ")),
        "reason" => get(full, "reason", "n/a")
    )
end

"""
    check_address_compact(address::String)::Dict

Convenience wrapper combining check_address + compact adapter in one call.
Never throws.
"""
function check_address_compact(address::String)::Dict
    try
        return compact_blacklist_entry(check_address(address))
    catch e
        @warn "compact blacklist check failed" address error=e
        return Dict(
            "address" => address,
            "is_blacklisted" => false,
            "risk_score" => 0.0,
            "sources" => String[],
            "updated_at" => Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"),
            "reason" => "error"
        )
    end
end

"""
    get_stats()::Dict

Get current statistics about the blacklist service.
"""
function get_stats()::Dict
    return Dict(
        "total_addresses" => length(STATE.scam_addresses),
        "last_update" => STATE.last_update,
        "sources_active" => (isempty(SOLANA_URLS_DEFAULT) ? 0 : 1) + (isempty(CHAINABUSE_URLS_DEFAULT) ? 0 : 1) + (isempty(EXTRA_URLS_DEFAULT) ? 0 : 1),
        "cache_type" => "In-Memory",
        "update_interval_minutes" => STATE.update_interval_seconds ÷ 60
    )
end

# ========================================
# UTILITY FUNCTIONS
# ========================================

"""
    _should_update()::Bool

Check if the blacklist data is stale and needs to be updated.
"""
function _should_update()::Bool
    lock(STATE.lock) do
        if isnothing(STATE.last_update)
            return true
        end
        return (now(UTC) - STATE.last_update).value > (STATE.update_interval_seconds * 1000)
    end
end

end # module BlacklistChecker
