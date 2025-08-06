# backend-julia/src/agents/LLMIntegration.jl

"""
LLM Integration Module for Agents.jl

Provides a common interface for interacting with various Language Model providers,
supporting pluggability and advanced features.
"""
module LLMIntegration

using Logging, Pkg # Use Pkg to check package availability
using JSON3 # Needed for parsing/serializing provider-specific configs and request/response bodies
using HTTP  # For making direct HTTP calls

# Import the abstract type from the Agents module
import ..AgentCore: AbstractLLMIntegration, DetectiveMemory, InvestigationTask # Relative import for sibling module in parent dir
# Config is now loaded by framework
import ..Config: get_config

export chat, chat_stream, get_provider_status, # Export the new status function
       analyze_wallet_with_llm, generate_investigation_report, get_detective_insights,
       create_detective_prompt, format_investigation_for_llm

# --- Concrete Implementations of AbstractLLMIntegration ---
struct OpenAILLMIntegration <: AbstractLLMIntegration end
struct AnthropicLLMIntegration <: AbstractLLMIntegration end
struct LlamaLLMIntegration <: AbstractLLMIntegration end
struct MistralLLMIntegration <: AbstractLLMIntegration end
struct CohereLLMIntegration <: AbstractLLMIntegration end
# struct GeminiLLMIntegration <: AbstractLLMIntegration end  # REMOVED - not used
struct EchoLLMIntegration <: AbstractLLMIntegration end # Fallback

# --- Provider Availability Checks (Conceptual) ---
is_openai_available() = true
is_anthropic_available() = true # For direct HTTP, assume available if configured
# ... other availability checks (can be enhanced later if needed)


"""
    chat(llm::AbstractLLMIntegration, prompt::String; cfg::Dict)

Generic fallback. Concrete types must implement their own `chat` method.
"""
function chat(llm::AbstractLLMIntegration, prompt::String; cfg::Dict)
    @warn "Chat method not implemented for LLM integration type $(typeof(llm)). Falling back to echo."
    return "[LLM Integration Error] Echo: " * prompt
end

"""
    chat_stream(llm::AbstractLLMIntegration, prompt::String; cfg::Dict)

Generic fallback for streaming chat. Concrete types must implement their own `chat_stream` method.
Returns a Channel that yields response chunks.
"""
function chat_stream(llm::AbstractLLMIntegration, prompt::String; cfg::Dict)
    @warn "Streaming chat method not implemented for LLM integration type $(typeof(llm)). Falling back to non-streaming chat."
    return Channel{String}(1) do ch
        try
            response = chat(llm, prompt; cfg)
            put!(ch, response)
        finally
            close(ch)
        end
    end
end

# --- OpenAI Implementation using Direct HTTP ---
function chat(llm::OpenAILLMIntegration, prompt::String; cfg::Dict)
    api_key = get(ENV, "OPENAI_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        @error "OpenAI API key not found in ENV or agent configuration."
        return "[LLM ERROR: OpenAI API Key Missing]"
    end

    model = get(cfg, "model", "gpt-4o-mini") # OpenAI model
    temperature = get(cfg, "temperature", 0.7)
    max_tokens_to_sample = get(cfg, "max_tokens", 1024) # Renamed for clarity, maps to OpenAI's max_tokens
    system_prompt_content = get(cfg, "system_prompt", "")
    openai_api_base = get(cfg, "api_base", "https://api.openai.com/v1")
    chat_endpoint = "$openai_api_base/chat/completions"

    headers = Dict(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $api_key"
    )

    messages = []
    if !isempty(system_prompt_content)
        push!(messages, Dict("role" => "system", "content" => system_prompt_content))
    end
    push!(messages, Dict("role" => "user", "content" => prompt))

    payload = Dict(
        "model" => model,
        "messages" => messages,
        "temperature" => temperature,
        "max_tokens" => max_tokens_to_sample
    )

    # Add support for streaming output
    if get(cfg, "stream", false)
        payload["stream"] = true
        # If streaming output is enabled, return Channel directly
        return chat_stream(llm, prompt; cfg)
    end

    json_payload = JSON3.write(payload)
    @debug "Sending request to OpenAI" endpoint=chat_endpoint model=model
    try
        response = HTTP.post(chat_endpoint, headers, json_payload; readtimeout=get(cfg, "request_timeout_seconds", 60))
        response_body_str = String(response.body)
        @debug "OpenAI Response Status: $(response.status)"

        if response.status == 200
            json_response = JSON3.read(response_body_str)
            if haskey(json_response, "choices") && !isempty(json_response.choices) &&
               haskey(json_response.choices[1], "message") && haskey(json_response.choices[1].message, "content")
                return json_response.choices[1].message.content
            else
                @error "OpenAI response format error." full_response=json_response
                return "[LLM ERROR: OpenAI response format error]"
            end
        else
            @error "OpenAI API request failed" status=response.status response_body=response_body_str
            error_details = response_body_str # Basic error detail
            try # Try to parse more specific error
                json_error = JSON3.read(response_body_str)
                if haskey(json_error, "error") && haskey(json_error.error, "message")
                    error_details = json_error.error.message
                end
            catch end
            return "[LLM ERROR: OpenAI API Status $(response.status) - $(error_details)]"
        end
    catch e
        @error "Exception during OpenAI API call" exception=(e, catch_backtrace())
        return "[LLM ERROR: Exception - $(string(e))]"
    end
end

"""
    chat_stream(llm::OpenAILLMIntegration, prompt::String; cfg::Dict)

Streaming chat implementation for OpenAI.
Returns a Channel that yields response chunks.
"""
function chat_stream(llm::OpenAILLMIntegration, prompt::String; cfg::Dict)
    api_key = get(ENV, "OPENAI_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        @error "OpenAI API key not found in ENV or agent configuration."
        return Channel{String}(0) do ch; close(ch); end
    end

    model = get(cfg, "model", "gpt-4o-mini")
    temperature = get(cfg, "temperature", 0.7)
    max_tokens_to_sample = get(cfg, "max_tokens", 1024)
    system_prompt_content = get(cfg, "system_prompt", "")
    openai_api_base = get(cfg, "api_base", "https://api.openai.com/v1")
    chat_endpoint = "$openai_api_base/chat/completions"

    headers = Dict(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $api_key"
    )

    messages = []
    if !isempty(system_prompt_content)
        push!(messages, Dict("role" => "system", "content" => system_prompt_content))
    end
    push!(messages, Dict("role" => "user", "content" => prompt))

    payload = Dict(
        "model" => model,
        "messages" => messages,
        "temperature" => temperature,
        "max_tokens" => max_tokens_to_sample,
        "stream" => true
    )

    json_payload = JSON3.write(payload)

    return Channel{String}(10) do ch
        try
            HTTP.open("POST", chat_endpoint, headers) do stream
                write(stream, json_payload)
                HTTP.closewrite(stream)
                r = HTTP.startread(stream)
                isdone = false
                while !isdone
                    if eof(stream)
                        break
                    end
                    masterchunk = String(readavailable(stream))
                    chunks = String.(filter(!isempty, split(masterchunk, "\n")))
                    for chunk in chunks
                        if occursin(chunk, "data: [DONE]")
                            isdone = true
                            break
                        end
                        if startswith(chunk, "data: ")
                            data = chunk[7:end] # Remove "data: " prefix
                            if data == "[DONE]"
                                break
                            end
                            try
                                json_response = JSON3.read(data)
                                if haskey(json_response, "choices") && !isempty(json_response.choices) &&
                                   haskey(json_response.choices[1], "delta")
                                    delta = json_response.choices[1].delta
                                    if haskey(delta, "content")
                                        content = delta["content"]
                                        put!(ch, content)  # Push to Channel
                                    end
                                end
                            catch e
                                @warn "Error parsing streaming response" error=e
                            end
                        end
                    end
                end
                HTTP.closeread(stream)
            end
        finally
            close(ch)
        end
    end
end

# Helper function: process OpenAI streaming response
function process_openai_stream_response(response_body::String)
    result = ""
    for line in eachline(IOBuffer(response_body))
        if !isempty(line) && startswith(line, "data: ")
            data = line[7:end] # Remove "data: " prefix
            if data == "[DONE]"
                break
            end
            try
                json_response = JSON3.read(data)
                if haskey(json_response, "choices") && !isempty(json_response.choices) &&
                   haskey(json_response.choices[1], "delta") && haskey(json_response.choices[1].delta, "content")
                    content = json_response.choices[1].delta.content
                    if !isempty(content)
                        result *= content
                    end
                end
            catch e
                @warn "Error parsing streaming response" error=e
            end
        end
    end
    return result
end

# --- Anthropic (Claude) Implementation using Direct HTTP ---
function chat(llm::AnthropicLLMIntegration, prompt::String; cfg::Dict)
    api_key = get(ENV, "ANTHROPIC_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        @error "Anthropic API key not found in ENV or agent configuration."
        return "[LLM ERROR: Anthropic API Key Missing]"
    end

    model = get(cfg, "model", "claude-3-haiku-20240307") # Anthropic model
    max_tokens_to_sample = get(cfg, "max_tokens", 1024) # Anthropic uses "max_tokens"
    temperature = get(cfg, "temperature", 0.7)
    system_prompt_content = get(cfg, "system_prompt", "") # Anthropic uses a "system" parameter
    anthropic_api_base = get(cfg, "api_base", "https://api.anthropic.com/v1")
    messages_endpoint = "$anthropic_api_base/messages"
    anthropic_version = get(cfg, "anthropic_version", "2023-06-01")

    headers = Dict(
        "Content-Type" => "application/json",
        "x-api-key" => api_key,
        "anthropic-version" => anthropic_version
    )

    # Anthropic's message format is slightly different
    messages = [
        Dict("role" => "user", "content" => prompt)
    ]

    payload = Dict(
        "model" => model,
        "messages" => messages,
        "max_tokens" => max_tokens_to_sample,
        "temperature" => temperature
    )
    if !isempty(system_prompt_content)
        payload["system"] = system_prompt_content
    end
    # Add other Anthropic specific parameters from cfg if needed (e.g., top_p, top_k, stream)
    # if haskey(cfg, "stream") && cfg["stream"] == true
    #     payload["stream"] = true
    #     # Note: Handling streaming responses would require different logic below
    # end

    json_payload = JSON3.write(payload)
    @debug "Sending request to Anthropic Messages API" endpoint=messages_endpoint model=model
    try
        response = HTTP.post(messages_endpoint, headers, json_payload; readtimeout=get(cfg, "request_timeout_seconds", 60))
        response_body_str = String(response.body)
        @debug "Anthropic Response Status: $(response.status)"

        if response.status == 200
            json_response = JSON3.read(response_body_str)
            # Anthropic response structure: content is an array of blocks, usually one text block
            if haskey(json_response, "content") && !isempty(json_response.content) &&
               haskey(json_response.content[1], "type") && json_response.content[1].type == "text" &&
               haskey(json_response.content[1], "text")
                return json_response.content[1].text
            else
                @error "Anthropic response format error." full_response=json_response
                return "[LLM ERROR: Anthropic response format error]"
            end
        else
            @error "Anthropic API request failed" status=response.status response_body=response_body_str
            error_details = response_body_str # Basic error detail
            try # Try to parse more specific error
                json_error = JSON3.read(response_body_str)
                if haskey(json_error, "error") && haskey(json_error.error, "message")
                    error_details = json_error.error.message
                elseif haskey(json_error, "type") && haskey(json_error, "message") # Another common error format
                    error_details = "$(json_error.type): $(json_error.message)"
                end
            catch end
            return "[LLM ERROR: Anthropic API Status $(response.status) - $(error_details)]"
        end
    catch e
        @error "Exception during Anthropic API call" exception=(e, catch_backtrace())
        return "[LLM ERROR: Exception - $(string(e))]"
    end
end


# --- Placeholder Implementations for Other Providers (using direct HTTP) ---
function chat(llm::LlamaLLMIntegration, prompt::String; cfg::Dict)
    endpoint_url = get(cfg, "endpoint_url", get(ENV, "LLAMA_ENDPOINT_URL", ""))
    api_key = get(cfg, "api_key", get(ENV, "LLAMA_API_KEY", "")) # Generic key name
    model_identifier = get(cfg, "model", "llama3-8b-8192") # Example model, user must configure

    is_local_endpoint = occursin("localhost", endpoint_url) || occursin("127.0.0.1", endpoint_url)

    if isempty(endpoint_url)
        @warn "Llama endpoint URL not found in agent configuration or ENV. Using mock response."
        return """
        [MOCK Llama RESPONSE]
        Llama integration requires 'endpoint_url' to be configured.
        For your prompt: "$(prompt)", a possible answer could be:
        "This is a mock response from the Llama integration. Please configure your Llama endpoint."
        """
    end

    if !is_local_endpoint && isempty(api_key)
        @warn "Llama API key not found for external endpoint '$endpoint_url'. Using mock response. Some endpoints may not require a key."
        # Some public or self-hosted endpoints might not need a key.
        # We could proceed if user explicitly configured no key, but for safety, mock if external and no key.
        # However, to allow keyless external endpoints, we can proceed but log a warning.
        # For now, let's be strict: if external and no key, mock. User can pass an empty string as key if truly keyless.
        # Reconsidering: Many self-hosted or research endpoints are keyless. Let's allow it but warn.
        if get(cfg, "requires_api_key", true) && isempty(api_key) # Add a config to specify if key is needed
             @warn "Llama API key not found for external endpoint '$endpoint_url' and 'requires_api_key' is true or default. Using mock response."
             return """
             [MOCK Llama RESPONSE]
             Llama API key not provided for external endpoint.
             For your prompt: "$(prompt)", a possible answer could be:
             "This is a mock response. Configure LLAMA_API_KEY or set 'requires_api_key': false in config if endpoint is keyless."
             """
        end
    end

    headers = Dict("Content-Type" => "application/json")
    if !isempty(api_key)
        headers["Authorization"] = "Bearer $api_key"
    end

    # Assuming an OpenAI-compatible API structure for the Llama endpoint
    # Users might need to adjust this payload based on their specific Llama hosting solution.
    messages = [Dict("role" => "user", "content" => prompt)]
    system_prompt_content = get(cfg, "system_prompt", "")
    if !isempty(system_prompt_content)
        pushfirst!(messages, Dict("role" => "system", "content" => system_prompt_content))
    end

    payload = Dict(
        "model" => model_identifier,
        "messages" => messages,
        "temperature" => get(cfg, "temperature", 0.7),
        "max_tokens" => get(cfg, "max_tokens", 1024)
        # Add other common parameters like "stream" if supported by endpoint
    )

    json_payload = JSON3.write(payload)
    @debug "Sending request to Llama endpoint" endpoint=endpoint_url model=model_identifier
    try
        response = HTTP.post(endpoint_url, headers, json_payload; readtimeout=get(cfg, "request_timeout_seconds", 120))
        response_body_str = String(response.body)
        @debug "Llama Endpoint Response Status: $(response.status)"

        if response.status == 200
            json_response = JSON3.read(response_body_str)
            # Assuming OpenAI-compatible response structure:
            if haskey(json_response, "choices") && !isempty(json_response.choices) &&
               haskey(json_response.choices[1], "message") && haskey(json_response.choices[1].message, "content")
                return json_response.choices[1].message.content
            # Fallback for some other common structures (e.g. direct text or Groq-like)
            elseif haskey(json_response, "text") # Direct text
                return json_response.text
            elseif haskey(json_response, "generated_text") # HuggingFace TGI
                return json_response.generated_text
            else
                @error "Llama endpoint response format error. Expected OpenAI-like structure or known alternatives." full_response=json_response
                return "[LLM ERROR: Llama endpoint response format error]"
            end
        else
            @error "Llama endpoint API request failed" status=response.status response_body=response_body_str
            error_details = response_body_str
            try
                json_error = JSON3.read(response_body_str)
                if haskey(json_error, "error") && haskey(json_error.error, "message")
                    error_details = json_error.error.message
                elseif haskey(json_error, "message")
                     error_details = json_error.message
                elseif haskey(json_error, "detail") && isa(json_error.detail, String)
                    error_details = json_error.detail
                end
            catch end
            return "[LLM ERROR: Llama Endpoint API Status $(response.status) - $(error_details)]"
        end
    catch e
        @error "Exception during Llama endpoint API call" exception=(e, catch_backtrace())
        return "[LLM ERROR: Exception - $(string(e))]"
    end
end

function chat(llm::MistralLLMIntegration, prompt::String; cfg::Dict)
    api_key = get(ENV, "MISTRAL_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        @warn "Mistral API key not found in ENV or agent configuration. Using mock response."
        return """
        [MOCK Mistral RESPONSE]
        If an API key were provided, I would have contacted Mistral AI.
        For your prompt: "$(prompt)", a possible answer could be:
        "This is a mock response from the Mistral integration. Please configure your MISTRAL_API_KEY."
        """
    end

    model = get(cfg, "model", "mistral-small-latest") # Default Mistral model
    temperature = get(cfg, "temperature", 0.7)
    max_tokens_to_sample = get(cfg, "max_tokens", 1024)
    system_prompt_content = get(cfg, "system_prompt", "")
    mistral_api_base = get(cfg, "api_base", "https://api.mistral.ai/v1")
    chat_endpoint = "$mistral_api_base/chat/completions"

    headers = Dict(
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Bearer $api_key"
    )

    messages = []
    if !isempty(system_prompt_content)
        # Mistral's API format for system prompt might differ or be part of the user message context
        # For simplicity, prepending to user prompt if system prompt is basic.
        # A more robust solution would check Mistral's exact API for system messages.
        # Current Mistral API uses a similar message structure to OpenAI.
        push!(messages, Dict("role" => "system", "content" => system_prompt_content))
    end
    push!(messages, Dict("role" => "user", "content" => prompt))

    payload = Dict(
        "model" => model,
        "messages" => messages,
        "temperature" => temperature,
        "max_tokens" => max_tokens_to_sample
        # "safe_prompt" => get(cfg, "safe_prompt", false) # Example of another Mistral param
    )

    json_payload = JSON3.write(payload)
    @debug "Sending request to Mistral AI" endpoint=chat_endpoint model=model
    try
        response = HTTP.post(chat_endpoint, headers, json_payload; readtimeout=get(cfg, "request_timeout_seconds", 60))
        response_body_str = String(response.body)
        @debug "Mistral AI Response Status: $(response.status)"

        if response.status == 200
            json_response = JSON3.read(response_body_str)
            if haskey(json_response, "choices") && !isempty(json_response.choices) &&
               haskey(json_response.choices[1], "message") && haskey(json_response.choices[1].message, "content")
                return json_response.choices[1].message.content
            else
                @error "Mistral AI response format error." full_response=json_response
                return "[LLM ERROR: Mistral AI response format error]"
            end
        else
            @error "Mistral AI API request failed" status=response.status response_body=response_body_str
            error_details = response_body_str
            try
                json_error = JSON3.read(response_body_str)
                if haskey(json_error, "message")
                    error_details = json_error.message
                elseif haskey(json_error, "detail") && isa(json_error.detail, String) # Another possible error format
                    error_details = json_error.detail
                elseif haskey(json_error, "detail") && isa(json_error.detail, Vector) && !isempty(json_error.detail) && haskey(json_error.detail[1], "msg")
                     error_details = json_error.detail[1].msg # For validation errors
                end
            catch end
            return "[LLM ERROR: Mistral API Status $(response.status) - $(error_details)]"
        end
    catch e
        @error "Exception during Mistral AI API call" exception=(e, catch_backtrace())
        return "[LLM ERROR: Exception - $(string(e))]"
    end
end

function chat(llm::CohereLLMIntegration, prompt::String; cfg::Dict)
    api_key = get(ENV, "COHERE_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        @warn "Cohere API key not found in ENV or agent configuration. Using mock response."
        return """
        [MOCK Cohere RESPONSE]
        If an API key were provided, I would have contacted Cohere.
        For your prompt: "$(prompt)", a possible answer could be:
        "This is a mock response from the Cohere integration. Please configure your COHERE_API_KEY."
        """
    end

    model = get(cfg, "model", "command-r") # Default Cohere model
    temperature = get(cfg, "temperature", 0.3) # Cohere's default is often lower
    max_tokens = get(cfg, "max_tokens", 1024)
    # Cohere uses `chat_history` and `message`
    # system_prompt can be part of chat_history or a preamble to the message
    system_prompt_content = get(cfg, "system_prompt", "")
    cohere_api_base = get(cfg, "api_base", "https://api.cohere.ai/v1")
    chat_endpoint = "$cohere_api_base/chat"

    headers = Dict(
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $api_key",
        "Cohere-Version" => get(cfg, "cohere_version", "2022-12-06") # Example version
    )

    # Construct chat history if needed, or just send the message
    # For simplicity, if system_prompt is provided, we can prepend it to the user's prompt
    # or structure it as a system turn in chat_history if the model supports it well.
    # Cohere's chat endpoint takes a `message` and optional `chat_history`.
    # A `preamble` can also be used for system-level instructions.

    payload = Dict{String, Any}(
        "model" => model,
        "message" => isempty(system_prompt_content) ? prompt : system_prompt_content * "\n\nUser: " * prompt, # Simple prepend for system
        "temperature" => temperature,
        "max_tokens" => max_tokens
        # "chat_history" => [], # Example: [{"role": "USER", "message": "Previous message"}]
        # "preamble" => system_prompt_content, # Alternative for system prompt
        # "connectors" => [{"id": "web-search"}] # Example for using Cohere connectors
    )
    # More sophisticated system prompt handling:
    if haskey(cfg, "preamble") && !isempty(cfg["preamble"])
        payload["preamble"] = cfg["preamble"]
        payload["message"] = prompt # Use raw prompt if preamble is used
    elseif !isempty(system_prompt_content) && !haskey(cfg, "preamble")
        # If system_prompt is given but not preamble, use it in chat_history
        payload["chat_history"] = [Dict("role" => "SYSTEM", "message" => system_prompt_content)]
        payload["message"] = prompt
    end


    json_payload = JSON3.write(payload)
    @debug "Sending request to Cohere" endpoint=chat_endpoint model=model
    try
        response = HTTP.post(chat_endpoint, headers, json_payload; readtimeout=get(cfg, "request_timeout_seconds", 60))
        response_body_str = String(response.body)
        @debug "Cohere Response Status: $(response.status)"

        if response.status == 200
            json_response = JSON3.read(response_body_str)
            # Cohere's chat response structure has a "text" field for the reply.
            # It might also have "chat_history", "tool_calls", etc.
            if haskey(json_response, "text")
                return json_response.text
            elseif haskey(json_response, "tool_calls") && !isnothing(json_response.tool_calls) && !isempty(json_response.tool_calls)
                # Handle tool calls if necessary, or return a representation
                return "[Cohere Tool Call Requested: $(JSON3.write(json_response.tool_calls))]"
            else
                @error "Cohere response format error. Missing 'text' field." full_response=json_response
                return "[LLM ERROR: Cohere response format error]"
            end
        else
            @error "Cohere API request failed" status=response.status response_body=response_body_str
            error_details = response_body_str
            try
                json_error = JSON3.read(response_body_str)
                if haskey(json_error, "message")
                    error_details = json_error.message
                end
            catch end
            return "[LLM ERROR: Cohere API Status $(response.status) - $(error_details)]"
        end
    catch e
        @error "Exception during Cohere API call" exception=(e, catch_backtrace())
        return "[LLM ERROR: Exception - $(string(e))]"
    end
end

# Gemini integration removed - not used in Ghost Wallet Hunter

function chat(llm::EchoLLMIntegration, prompt::String; cfg::Dict)
    @debug "Using Echo LLM integration."
    return "[LLM disabled/echo] Echo: " * prompt
end


# --- Provider Status Check Functions ---

"""
    get_provider_status(llm::AbstractLLMIntegration, cfg::Dict)::Dict{String, Any}

Generic fallback for provider status. Concrete types should implement this.
"""
function get_provider_status(llm::AbstractLLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_type = string(typeof(llm))
    return Dict("provider" => provider_type, "status" => "unknown", "message" => "Status check not implemented for $provider_type.")
end

function get_provider_status(llm::OpenAILLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_name = "OpenAI"
    api_key = get(ENV, "OPENAI_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        return Dict("provider" => provider_name, "status" => "misconfigured", "message" => "OpenAI API key not found.")
    end

    openai_api_base = get(cfg, "api_base", "https://api.openai.com/v1")
    models_endpoint = "$openai_api_base/models"
    headers = Dict("Authorization" => "Bearer $api_key")

    try
        response = HTTP.get(models_endpoint, headers; readtimeout=get(cfg, "status_check_timeout_seconds", 10))
        if response.status == 200
            # Optionally parse response.data to list some models or confirm structure
            return Dict("provider" => provider_name, "status" => "ok", "message" => "Successfully connected and listed models.")
        else
            return Dict("provider" => provider_name, "status" => "error", "message" => "API request to list models failed with status $(response.status).", "details" => String(response.body))
        end
    catch e
        return Dict("provider" => provider_name, "status" => "error", "message" => "Exception during OpenAI status check: $(string(e))")
    end
end

function get_provider_status(llm::AnthropicLLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_name = "Anthropic"
    api_key = get(ENV, "ANTHROPIC_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        return Dict("provider" => provider_name, "status" => "misconfigured", "message" => "Anthropic API key not found.")
    end
    # Anthropic doesn't have a simple free "ping" or "list models" endpoint.
    # A successful small chat request would confirm, but that costs tokens.
    # For now, if key is present, assume "configured".
    return Dict("provider" => provider_name, "status" => "configured", "message" => "Anthropic API key is present. Full connectivity test requires a chat request.")
end

function get_provider_status(llm::LlamaLLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_name = "Llama (Custom Endpoint)"
    endpoint_url = get(cfg, "endpoint_url", get(ENV, "LLAMA_ENDPOINT_URL", ""))
    if isempty(endpoint_url)
        return Dict("provider" => provider_name, "status" => "misconfigured", "message" => "Llama endpoint URL not found.")
    end
    # For custom endpoints, a simple HTTP GET or OPTIONS request might suffice as a health check if the endpoint supports it.
    # This is highly dependent on the specific Llama hosting.
    # For now, if endpoint_url is set, consider it "configured".
    # A real check might try HTTP.request("HEAD", endpoint_url) or similar.
    try
        # Attempt a HEAD request as a basic connectivity check
        response = HTTP.request("HEAD", endpoint_url; readtimeout=get(cfg, "status_check_timeout_seconds", 10))
        if response.status >= 200 && response.status < 400 # Broad success range
            return Dict("provider" => provider_name, "status" => "ok", "endpoint" => endpoint_url, "message" => "Endpoint reachable (HEAD request successful with status $(response.status)).")
        else
            return Dict("provider" => provider_name, "status" => "error", "endpoint" => endpoint_url, "message" => "Endpoint check (HEAD request) failed with status $(response.status).")
        end
    catch e
        return Dict("provider" => provider_name, "status" => "error", "endpoint" => endpoint_url, "message" => "Exception during Llama endpoint status check: $(string(e))")
    end
end

# Similar simplified status checks for Mistral, Cohere, Gemini
function get_provider_status(llm::MistralLLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_name = "Mistral"
    api_key = get(ENV, "MISTRAL_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        return Dict("provider" => provider_name, "status" => "misconfigured", "message" => "Mistral API key not found.")
    end
    # Could try /v1/models like OpenAI if Mistral supports it and it's a lightweight check.
    # For now, "configured" if key is present.
    return Dict("provider" => provider_name, "status" => "configured", "message" => "Mistral API key is present. Full connectivity test requires a chat/models request.")
end

function get_provider_status(llm::CohereLLMIntegration, cfg::Dict)::Dict{String, Any}
    provider_name = "Cohere"
    api_key = get(ENV, "COHERE_API_KEY", get(cfg, "api_key", ""))
    if isempty(api_key)
        return Dict("provider" => provider_name, "status" => "misconfigured", "message" => "Cohere API key not found.")
    end
    return Dict("provider" => provider_name, "status" => "configured", "message" => "Cohere API key is present. Full connectivity test requires an API request.")
end

# Gemini status check removed - not used in Ghost Wallet Hunter

function get_provider_status(llm::EchoLLMIntegration, cfg::Dict)::Dict{String, Any}
    return Dict("provider" => "Echo", "status" => "active", "message" => "Echo LLM is always active (local echo).")
end


# --- Helper function to create the correct LLM integration instance ---
function create_llm_integration(config::Dict{String, Any})::Union{AbstractLLMIntegration, Nothing}
    provider = lowercase(get(config, "provider", "none"))
    if provider == "openai"; return OpenAILLMIntegration()
    elseif provider == "anthropic"; return AnthropicLLMIntegration()
    elseif provider == "llama"; return LlamaLLMIntegration()
    elseif provider == "mistral"; return MistralLLMIntegration()
    elseif provider == "cohere"; return CohereLLMIntegration()
    # elseif provider == "gemini"; return GeminiLLMIntegration()  # REMOVED - not used
    elseif provider == "echo"; return EchoLLMIntegration()
    elseif provider == "none" || isempty(provider); return nothing
    else
        @warn "Unknown LLM provider '$provider'. No LLM integration created."
        return nothing
    end
end

# --- Placeholder for Advanced LLM Features ---
# ... (select_model, apply_prompt_template, etc. remain as conceptual placeholders) ...

# ----------------------------------------------------------------------
# DETECTIVE-SPECIFIC LLM FUNCTIONS
# ----------------------------------------------------------------------

const DETECTIVE_PERSONALITIES = Dict(
    "poirot" => "You are Hercule Poirot, the meticulous Belgian detective. Approach this blockchain analysis with your characteristic attention to detail, logical methodology, and systematic reasoning. Focus on methodical patterns and financial inconsistencies.",

    "marple" => "You are Miss Jane Marple, with your keen insight into human nature. Analyze this blockchain data as you would observe a village community, looking for social patterns, behavioral anomalies, and community connections.",

    "spade" => "You are Sam Spade, the hard-boiled detective. Take a no-nonsense, aggressive approach to this blockchain investigation. Focus on criminal patterns, money laundering indicators, and illicit activities.",

    "marlowee" => "You are Philip Marlowe, the cynical detective. Approach this analysis with your characteristic skepticism about power and corruption. Look for institutional fraud, power abuse, and corruption indicators.",

    "dupin" => "You are C. Auguste Dupin, the analytical reasoner. Apply mathematical and statistical approaches to this blockchain data. Focus on algorithmic patterns, statistical outliers, and mathematical anomalies.",

    "shadow" => "You are The Shadow, who knows what evil lurks. Focus on hidden networks, covert operations, and stealth activities in this blockchain analysis. Uncover what others try to conceal.",

    "raven" => "You are The Raven, analyzing the dark psychology behind blockchain activities. Focus on behavioral patterns, psychological motivations, and dark intentions behind transactions."
)

"""
    create_detective_prompt(detective_type::String, wallet_data::Dict{String, Any}, investigation_type::String="standard") -> String

Creates a detective-specific prompt for LLM analysis of blockchain data.
"""
function create_detective_prompt(detective_type::String, wallet_data::Dict{String, Any}, investigation_type::String="standard")
    personality = get(DETECTIVE_PERSONALITIES, detective_type, DETECTIVE_PERSONALITIES["poirot"])

    analysis_depth = if investigation_type == "quick"
        "Provide a rapid analysis focusing on immediate red flags. Keep response concise."
    elseif investigation_type == "deep"
        "Conduct a thorough, detailed analysis. Examine all patterns and provide comprehensive insights."
    else
        "Provide a balanced analysis with key findings and actionable insights."
    end

    formatted_data = format_investigation_for_llm(wallet_data)

    prompt = """
$personality

$analysis_depth

BLOCKCHAIN INVESTIGATION DATA:
$formatted_data

ANALYSIS REQUIREMENTS:
Please analyze this blockchain data and provide:

1. **Risk Assessment**: Assign a risk score from 0.0 (safe) to 1.0 (highly suspicious)
2. **Key Findings**: List the most important discoveries
3. **Suspicious Patterns**: Identify specific patterns that raise concerns
4. **Behavioral Analysis**: Analyze transaction behaviors and timing
5. **Recommendations**: Suggest next investigative steps
6. **Confidence Level**: Rate your confidence in this analysis (0.0-1.0)

**Detective Focus**: Apply your unique investigative methodology and provide insights that reflect your specialized approach to pattern recognition.

Please structure your response as JSON:
{
    "risk_score": 0.0-1.0,
    "confidence": 0.0-1.0,
    "risk_level": "LOW|MEDIUM|HIGH|CRITICAL",
    "key_findings": ["finding1", "finding2"],
    "suspicious_patterns": ["pattern1", "pattern2"],
    "behavioral_analysis": "description of transaction behavior",
    "detective_insights": "your specialized observations",
    "recommendations": ["action1", "action2"],
    "summary": "brief overall assessment"
}
"""

    return prompt
end

"""
    format_investigation_for_llm(wallet_data::Dict{String, Any}) -> String

Formats wallet investigation data for LLM analysis.
"""
function format_investigation_for_llm(wallet_data::Dict{String, Any})
    formatted = "WALLET INVESTIGATION SUMMARY:\n"

    # Basic wallet info
    if haskey(wallet_data, "address")
        formatted *= "Wallet Address: $(wallet_data["address"])\n"
    end

    if haskey(wallet_data, "balance")
        formatted *= "Current Balance: $(wallet_data["balance"])\n"
    end

    # Transaction analysis
    if haskey(wallet_data, "transactions") && !isempty(wallet_data["transactions"])
        transactions = wallet_data["transactions"]
        formatted *= "\nTRANSACTION ANALYSIS:\n"
        formatted *= "Total Transactions: $(length(transactions))\n"

        # Recent activity
        formatted *= "\nRECENT TRANSACTIONS (last 5):\n"
        recent = transactions[1:min(5, length(transactions))]
        for (i, tx) in enumerate(recent)
            amount = get(tx, "amount", "unknown")
            type_str = get(tx, "type", "transfer")
            timestamp = get(tx, "timestamp", "unknown")
            formatted *= "  $i. [$timestamp] $type_str: $amount\n"
        end

        # Pattern indicators
        if haskey(wallet_data, "patterns")
            formatted *= "\nDETECTED PATTERNS:\n"
            for pattern in wallet_data["patterns"]
                formatted *= "- $pattern\n"
            end
        end
    end

    # Risk indicators
    if haskey(wallet_data, "risk_indicators")
        formatted *= "\nRISK INDICATORS:\n"
        for indicator in wallet_data["risk_indicators"]
            formatted *= "- $indicator\n"
        end
    end

    # Connected addresses
    if haskey(wallet_data, "connected_addresses") && !isempty(wallet_data["connected_addresses"])
        formatted *= "\nCONNECTED ADDRESSES:\n"
        for addr in wallet_data["connected_addresses"][1:min(5, length(wallet_data["connected_addresses"]))]
            formatted *= "- $addr\n"
        end
    end

    return formatted
end

"""
    analyze_wallet_with_llm(llm::AbstractLLMIntegration, wallet_data::Dict{String, Any}, detective_type::String="poirot", investigation_type::String="standard") -> Dict{String, Any}

Analyzes wallet data using LLM with detective-specific approach.
"""
function analyze_wallet_with_llm(llm::AbstractLLMIntegration, wallet_data::Dict{String, Any}, detective_type::String="poirot", investigation_type::String="standard")
    # Create detective-specific prompt
    prompt = create_detective_prompt(detective_type, wallet_data, investigation_type)

    # Configure LLM for analysis
    llm_config = Dict{String, Any}(
        "model" => get_config("detective.ai_analysis.model", "gpt-4"),
        "temperature" => get_config("detective.ai_analysis.temperature", 0.1),
        "max_tokens" => get_config("detective.ai_analysis.max_tokens", 4000)
    )

    try
        # Get LLM response
        response = chat(llm, prompt, cfg=llm_config)

        # Try to parse JSON response
        analysis_result = try
            JSON3.read(response)
        catch json_error
            @warn "Failed to parse LLM response as JSON: $json_error"
            # Fallback to text analysis
            Dict{String, Any}(
                "risk_score" => 0.5,
                "confidence" => 0.3,
                "risk_level" => "MEDIUM",
                "key_findings" => ["LLM analysis completed but JSON parsing failed"],
                "suspicious_patterns" => [],
                "behavioral_analysis" => response,
                "detective_insights" => "Analysis available in behavioral_analysis field",
                "recommendations" => ["Review analysis manually"],
                "summary" => "LLM analysis completed"
            )
        end

        # Add metadata
        result = Dict{String, Any}(
            "analysis" => analysis_result,
            "detective_type" => detective_type,
            "investigation_type" => investigation_type,
            "llm_model" => llm_config["model"],
            "timestamp" => string(now()),
            "success" => true
        )

        @debug "LLM analysis completed for wallet $(get(wallet_data, "address", "unknown"))"
        return result

    catch e
        @error "LLM analysis failed: $e"

        # Return fallback analysis
        return Dict{String, Any}(
            "success" => false,
            "error" => string(e),
            "detective_type" => detective_type,
            "timestamp" => string(now()),
            "fallback_analysis" => create_fallback_analysis(wallet_data)
        )
    end
end

"""
    generate_investigation_report(llm::AbstractLLMIntegration, investigation::InvestigationTask, memory::DetectiveMemory) -> Dict{String, Any}

Generates a comprehensive investigation report using LLM.
"""
function generate_investigation_report(llm::AbstractLLMIntegration, investigation::InvestigationTask, memory::DetectiveMemory)
    # Create comprehensive report prompt
    prompt = create_report_prompt(investigation, memory)

    llm_config = Dict{String, Any}(
        "model" => get_config("detective.ai_analysis.model", "gpt-4"),
        "temperature" => 0.2,  # Slightly higher for report generation
        "max_tokens" => 6000   # More tokens for comprehensive reports
    )

    try
        response = chat(llm, prompt, cfg=llm_config)

        return Dict{String, Any}(
            "report" => response,
            "investigation_id" => investigation.id,
            "wallet_address" => investigation.wallet_address,
            "generated_at" => string(now()),
            "success" => true
        )

    catch e
        @error "Report generation failed: $e"
        return Dict{String, Any}(
            "success" => false,
            "error" => string(e),
            "investigation_id" => investigation.id
        )
    end
end

"""
    get_detective_insights(llm::AbstractLLMIntegration, patterns::Vector{String}, detective_type::String="poirot") -> Dict{String, Any}

Gets detective insights on specific patterns using LLM.
"""
function get_detective_insights(llm::AbstractLLMIntegration, patterns::Vector{String}, detective_type::String="poirot")
    personality = get(DETECTIVE_PERSONALITIES, detective_type, DETECTIVE_PERSONALITIES["poirot"])

    prompt = """
$personality

I've identified the following blockchain patterns during an investigation:

DETECTED PATTERNS:
$(join(patterns, "\n- "))

Based on your detective expertise, please provide insights on:
1. What do these patterns suggest about the wallet's purpose?
2. Which patterns are most concerning and why?
3. What additional investigation angles would you pursue?
4. How do these patterns fit together in your analysis?

Provide your response in your characteristic investigative style, focusing on actionable insights.
"""

    llm_config = Dict{String, Any}(
        "model" => get_config("detective.ai_analysis.model", "gpt-4"),
        "temperature" => 0.3,
        "max_tokens" => 2000
    )

    try
        response = chat(llm, prompt, cfg=llm_config)
        return Dict{String, Any}(
            "insights" => response,
            "detective_type" => detective_type,
            "patterns_analyzed" => patterns,
            "success" => true,
            "timestamp" => string(now())
        )
    catch e
        return Dict{String, Any}(
            "success" => false,
            "error" => string(e),
            "detective_type" => detective_type
        )
    end
end

# Helper functions
function create_report_prompt(investigation::InvestigationTask, memory::DetectiveMemory)
    detective_type = get(investigation.parameters, "detective_type", "unknown")
    personality = get(DETECTIVE_PERSONALITIES, detective_type, "You are an experienced blockchain detective.")

    return """
$personality

Generate a comprehensive investigation report for the following case:

INVESTIGATION DETAILS:
- Investigation ID: $(investigation.id)
- Wallet Address: $(investigation.wallet_address)
- Investigation Type: $(investigation.task_type)
- Status: $(investigation.status)
- Duration: $(investigation.completed_at !== nothing ? investigation.completed_at - investigation.created_at : "Ongoing")

INVESTIGATION RESULTS:
$(JSON3.write(investigation.result, allow_inf=true))

DETECTIVE MEMORY CONTEXT:
- Total Previous Investigations: $(length(memory.investigation_history))
- Patterns in Cache: $(length(memory.pattern_cache))

Please create a professional investigation report that includes:

1. **EXECUTIVE SUMMARY**
2. **INVESTIGATION OVERVIEW**
3. **KEY FINDINGS**
4. **DETAILED ANALYSIS**
5. **RISK ASSESSMENT**
6. **PATTERNS IDENTIFIED**
7. **RECOMMENDATIONS**
8. **CONCLUSION**

Write this report in your characteristic detective style, suitable for stakeholders and potential legal proceedings.
"""
end

function create_fallback_analysis(wallet_data::Dict{String, Any})
    # Basic heuristic analysis when LLM fails
    transactions = get(wallet_data, "transactions", [])

    risk_score = 0.0
    risk_indicators = []

    # Simple heuristics
    if length(transactions) > 100
        risk_score += 0.2
        push!(risk_indicators, "High transaction volume")
    end

    if haskey(wallet_data, "risk_indicators")
        risk_score += length(wallet_data["risk_indicators"]) * 0.1
        append!(risk_indicators, wallet_data["risk_indicators"])
    end

    return Dict{String, Any}(
        "risk_score" => min(risk_score, 1.0),
        "confidence" => 0.3,  # Low confidence for fallback
        "risk_level" => risk_score > 0.7 ? "HIGH" : risk_score > 0.4 ? "MEDIUM" : "LOW",
        "key_findings" => ["Fallback analysis - LLM unavailable"],
        "suspicious_patterns" => risk_indicators,
        "behavioral_analysis" => "Basic heuristic analysis applied",
        "detective_insights" => "Limited analysis due to LLM failure",
        "recommendations" => ["Retry with LLM when available"],
        "summary" => "Fallback heuristic analysis completed"
    )
end

end # module LLMIntegration
