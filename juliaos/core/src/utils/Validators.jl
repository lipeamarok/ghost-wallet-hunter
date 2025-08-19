"""
Ghost Wallet Hunter - Validation Utilities (Julia)

Julia-native validation utilities for Solana addresses, transaction signatures,
and various data formats with enhanced performance and built-in type safety.
"""

module Validators

export validate_solana_address, validate_transaction_signature, validate_risk_score

using Base64
using JSON3

# Constants for validation
const BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
const SOLANA_ADDRESS_MIN_LENGTH = 32
const SOLANA_ADDRESS_MAX_LENGTH = 44
const SOLANA_SIGNATURE_LENGTH = 88

"""
Validate Solana wallet address format with enhanced checks.

# Arguments
- `address::String`: The wallet address to validate

# Returns
- `Bool`: true if valid, false otherwise

# Examples
```julia
validate_solana_address("11111111111111111111111111111112")  # true
validate_solana_address("invalid")  # false
```
"""
function validate_solana_address(address::String)::Bool
    try
        # Quick check for obviously invalid addresses
        if occursin("invalid", lowercase(address)) || occursin("_", address)
            return false
        end

        # Basic length check
        length(address) < SOLANA_ADDRESS_MIN_LENGTH && return false
        length(address) > SOLANA_ADDRESS_MAX_LENGTH && return false

        # Check for valid base58 characters
        for char in address
            char ∉ BASE58_ALPHABET && return false
        end

        # Additional checks for common invalid patterns
        # All zeros (except system program)
        if address == "11111111111111111111111111111112"
            return true  # System program ID
        end

        # All same character (likely invalid)
        if all(c -> c == address[1], address)
            return false
        end

        return true

    catch
        return false
    end
end

"""
Validate Solana transaction signature format.

# Arguments
- `signature::String`: The transaction signature to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_transaction_signature(signature::String)::Bool
    try
        # Exact length check for transaction signatures
        length(signature) != SOLANA_SIGNATURE_LENGTH && return false

        # Check for valid base58 characters
        for char in signature
            char ∉ BASE58_ALPHABET && return false
        end

        return true

    catch
        return false
    end
end

"""
Validate risk score is within valid range [0.0, 1.0].

# Arguments
- `score::Real`: The risk score to validate

# Returns
- `Bool`: true if valid (0.0 to 1.0), false otherwise
"""
function validate_risk_score(score::Real)::Bool
    try
        return 0.0 <= score <= 1.0
    catch
        return false
    end
end

"""
Validate transaction amount is positive and reasonable.

# Arguments
- `amount::Real`: The transaction amount to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_transaction_amount(amount::Real)::Bool
    try
        # Must be positive
        amount <= 0 && return false

        # Check for reasonable maximum (1 billion SOL)
        amount > 1_000_000_000 && return false

        # Check for tiny amounts that might be spam
        amount < 0.000001 && return false

        return true

    catch
        return false
    end
end

"""
Validate cluster size is within reasonable bounds.

# Arguments
- `size::Integer`: The cluster size to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_cluster_size(size::Integer)::Bool
    try
        return 1 <= size <= 10000  # Reasonable cluster size bounds
    catch
        return false
    end
end

"""
Validate time window for analysis (in seconds).

# Arguments
- `seconds::Real`: The time window in seconds

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_time_window(seconds::Real)::Bool
    try
        # Minimum 1 second, maximum 1 year
        return 1 <= seconds <= 365 * 24 * 3600
    catch
        return false
    end
end

"""
Validate URL format.

# Arguments
- `url::String`: The URL to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_url(url::String)::Bool
    try
        isempty(url) && return false

        # Basic URL pattern check
        url_pattern = r"^https?://[^\s/$.?#].[^\s]*$"

        return occursin(url_pattern, url)

    catch
        return false
    end
end

"""
Validate API key format (should be non-empty string).

# Arguments
- `api_key::String`: The API key to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_api_key(api_key::String)::Bool
    try
        # Must be non-empty and at least 10 characters
        length(api_key) >= 10
    catch
        return false
    end
end

"""
Validate hex string format.

# Arguments
- `hex_string::String`: The hex string to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_hex_string(hex_string::String)::Bool
    try
        isempty(hex_string) && return false

        # Check if all characters are valid hex
        hex_pattern = r"^[0-9a-fA-F]+$"

        return occursin(hex_pattern, hex_string)

    catch
        return false
    end
end

"""
Validate pagination parameters.

# Arguments
- `page::Integer`: Page number (1-based)
- `limit::Integer`: Items per page

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_pagination(page::Integer, limit::Integer)::Bool
    try
        # Page must be positive
        page < 1 && return false

        # Limit must be reasonable
        limit < 1 && return false
        limit > 1000 && return false  # Prevent excessive requests

        return true

    catch
        return false
    end
end

"""
Validate JSON string format.

# Arguments
- `json_string::String`: The JSON string to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_json_string(json_string::String)::Bool
    try
        JSON3.read(json_string)
        return true
    catch
        return false
    end
end

"""
Validate email address format (basic check).

# Arguments
- `email::String`: The email address to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_email(email::String)::Bool
    try
        isempty(email) && return false

        # Basic email pattern
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        return occursin(email_pattern, email)

    catch
        return false
    end
end

"""
Validate wallet analysis depth parameter.

# Arguments
- `depth::Integer`: Analysis depth level

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_analysis_depth(depth::Integer)::Bool
    try
        return 1 <= depth <= 10  # Reasonable analysis depth
    catch
        return false
    end
end

"""
Validate confidence score [0.0, 1.0].

# Arguments
- `confidence::Real`: The confidence score

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_confidence_score(confidence::Real)::Bool
    try
        return 0.0 <= confidence <= 1.0
    catch
        return false
    end
end

"""
Validate IP address format (IPv4).

# Arguments
- `ip::String`: The IP address to validate

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_ipv4(ip::String)::Bool
    try
        parts = split(ip, ".")
        length(parts) != 4 && return false

        for part in parts
            num = tryparse(Int, part)
            isnothing(num) && return false
            num < 0 || num > 255 && return false
        end

        return true

    catch
        return false
    end
end

"""
Batch validation for multiple Solana addresses.

# Arguments
- `addresses::Vector{String}`: Vector of addresses to validate

# Returns
- `Vector{Bool}`: Vector of validation results
"""
function validate_solana_addresses_batch(addresses::Vector{String})::Vector{Bool}
    return [validate_solana_address(addr) for addr in addresses]
end

"""
Validate and sanitize user input string.

# Arguments
- `input::String`: User input to validate
- `max_length::Integer`: Maximum allowed length (default: 1000)

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_user_input(input::String, max_length::Integer = 1000)::Bool
    try
        # Check length
        length(input) > max_length && return false

        # Check for potentially dangerous characters/patterns
        dangerous_patterns = [
            r"<script",
            r"javascript:",
            r"onload=",
            r"onerror=",
            r"eval\(",
            r"document\.",
            r"window\."
        ]

        for pattern in dangerous_patterns
            occursin(pattern, lowercase(input)) && return false
        end

        return true

    catch
        return false
    end
end

"""
Validate cryptocurrency symbol format.

# Arguments
- `symbol::String`: The cryptocurrency symbol

# Returns
- `Bool`: true if valid, false otherwise
"""
function validate_crypto_symbol(symbol::String)::Bool
    try
        isempty(symbol) && return false

        # Should be 2-10 characters, alphanumeric
        length(symbol) < 2 || length(symbol) > 10 && return false

        # Should contain only letters and numbers
        symbol_pattern = r"^[A-Za-z0-9]+$"

        return occursin(symbol_pattern, symbol)

    catch
        return false
    end
end

"""
Comprehensive validation suite for wallet analysis request.

# Arguments
- `wallet_address::String`: Wallet address
- `depth::Integer`: Analysis depth
- `time_window::Real`: Time window in seconds

# Returns
- `Dict{String, Any}`: Validation results with details
"""
function validate_analysis_request(wallet_address::String, depth::Integer, time_window::Real)::Dict{String, Any}
    results = Dict{String, Any}()

    results["wallet_address_valid"] = validate_solana_address(wallet_address)
    results["depth_valid"] = validate_analysis_depth(depth)
    results["time_window_valid"] = validate_time_window(time_window)

    results["all_valid"] = all(values(results))

    if !results["all_valid"]
        errors = String[]
        !results["wallet_address_valid"] && push!(errors, "Invalid wallet address format")
        !results["depth_valid"] && push!(errors, "Invalid analysis depth (must be 1-10)")
        !results["time_window_valid"] && push!(errors, "Invalid time window (must be 1 second to 1 year)")

        results["errors"] = errors
    end

    return results
end

"""
Health check for validators module.
"""
function health_check()::Dict{String, Any}
    return Dict(
        "status" => "operational",
        "module" => "Validators",
        "functions_available" => 20,
        "performance" => "native Julia speed",
        "timestamp" => string(now())
    )
end

# Export all validation functions
export validate_solana_address,
       validate_transaction_signature,
       validate_risk_score,
       validate_transaction_amount,
       validate_cluster_size,
       validate_time_window,
       validate_url,
       validate_api_key,
       validate_hex_string,
       validate_pagination,
       validate_json_string,
       validate_email,
       validate_analysis_depth,
       validate_confidence_score,
       validate_ipv4,
       validate_solana_addresses_batch,
       validate_user_input,
       validate_crypto_symbol,
       validate_analysis_request,
       health_check

end # module Validators
