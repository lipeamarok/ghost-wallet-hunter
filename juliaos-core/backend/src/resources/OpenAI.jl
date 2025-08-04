module OpenAI

"""
OpenAI API Integration for JuliaOS

This module provides OpenAI API integration for Ghost Wallet Hunter tools,
following the same pattern as the Gemini integration.
"""

using HTTP
using JSON3

struct OpenAIConfig
    api_key::String
    model_name::String
    temperature::Float64
    max_tokens::Int
    base_url::String

    function OpenAIConfig(;
        api_key::String,
        model_name::String = "gpt-3.5-turbo",
        temperature::Float64 = 0.7,
        max_tokens::Int = 1024,
        base_url::String = "https://api.openai.com/v1"
    )
        new(api_key, model_name, temperature, max_tokens, base_url)
    end
end

"""
    openai_util(config::OpenAIConfig, prompt::String) -> String

Makes an API call to OpenAI and returns the response.
"""
function openai_util(config::OpenAIConfig, prompt::String)
    if isempty(config.api_key)
        throw(ArgumentError("OpenAI API key is required"))
    end

    headers = [
        "Authorization" => "Bearer $(config.api_key)",
        "Content-Type" => "application/json"
    ]

    payload = Dict(
        "model" => config.model_name,
        "messages" => [
            Dict("role" => "user", "content" => prompt)
        ],
        "temperature" => config.temperature,
        "max_tokens" => config.max_tokens
    )

    try
        response = HTTP.post(
            "$(config.base_url)/chat/completions",
            headers,
            JSON3.write(payload);
            timeout = 30
        )

        if response.status == 200
            response_data = JSON3.read(String(response.body))

            if haskey(response_data, "choices") && length(response_data["choices"]) > 0
                content = response_data["choices"][1]["message"]["content"]
                return String(content)
            else
                throw(ErrorException("Invalid response format from OpenAI API"))
            end
        else
            error_body = String(response.body)
            throw(ErrorException("OpenAI API error ($(response.status)): $error_body"))
        end

    catch e
        if isa(e, HTTP.TimeoutError)
            throw(ErrorException("OpenAI API timeout"))
        elseif isa(e, HTTP.ConnectError)
            throw(ErrorException("Failed to connect to OpenAI API"))
        else
            rethrow(e)
        end
    end
end

"""
    openai_analyze_wallet(config::OpenAIConfig, wallet_data::Dict) -> String

Specialized function for wallet analysis using OpenAI.
"""
function openai_analyze_wallet(config::OpenAIConfig, wallet_data::Dict)
    wallet_address = get(wallet_data, "wallet_address", "unknown")
    risk_score = get(wallet_data, "risk_score", 0)
    patterns = get(wallet_data, "patterns", [])

    prompt = """
    Analyze this Ethereum wallet for suspicious activity:

    Wallet: $wallet_address
    Risk Score: $risk_score/100
    Detected Patterns: $(join(patterns, ", "))

    Provide a concise analysis including:
    1. Risk level assessment (LOW/MEDIUM/HIGH/CRITICAL)
    2. Main security concerns
    3. Recommended actions
    4. Confidence level (1-10)

    Response in Portuguese, maximum 400 words.
    """

    return openai_util(config, prompt)
end

"""
    openai_blacklist_analysis(config::OpenAIConfig, blacklist_data::Dict) -> String

Specialized function for blacklist analysis using OpenAI.
"""
function openai_blacklist_analysis(config::OpenAIConfig, blacklist_data::Dict)
    wallet_address = get(blacklist_data, "wallet_address", "unknown")
    is_blacklisted = get(blacklist_data, "is_blacklisted", false)
    sources = get(blacklist_data, "sources_checked", 0)
    risk_level = get(blacklist_data, "risk_level", "UNKNOWN")

    prompt = """
    Analyze blacklist check results for this wallet:

    Wallet: $wallet_address
    Blacklisted: $is_blacklisted
    Sources Checked: $sources
    Risk Level: $risk_level

    Provide analysis including:
    1. Threat assessment
    2. Compliance implications
    3. Recommended monitoring level
    4. Next steps for investigation

    Response in Portuguese, maximum 350 words.
    """

    return openai_util(config, prompt)
end

end
