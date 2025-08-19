module Resources

include("types/Errors.jl")
include("types/Telegram.jl")
include("OpenAI.jl")
include("Grok.jl")

using .Telegram
using .OpenAI
using .Grok

# ========================================
# 🤖 FUNÇÃO CENTRALIZADA PARA CHAMADAS DE IA
# ========================================

"""
    call_ai(provider::String, prompt::String; api_key::String="") -> String

Função centralizada para chamar qualquer provedor de IA.
Todos os logs e controles passam por aqui.

## Providers suportados:
- "openai" - OpenAI GPT models
- "grok" - xAI Grok models

## Exemplo:
```julia
response = call_ai("openai", "Analyze this wallet: 0x123...")
response = call_ai("grok", "Risk assessment for transactions", api_key="custom_key")
```
"""
function call_ai(provider::String, prompt::String; api_key::String="")
    println("🤖 [AI CALL] Provider: $provider")
    println("📝 [AI CALL] Prompt length: $(length(prompt)) chars")
    println("🔑 [AI CALL] API Key: $(isempty(api_key) ? "from ENV" : "provided")")

    try
        if provider == "openai"
            # Usa chave fornecida ou do ENV
            key = isempty(api_key) ? get(ENV, "OPENAI_API_KEY", "") : api_key
            if isempty(key)
                error("OpenAI API key not found in ENV or provided")
            end

            config = OpenAI.OpenAIConfig(api_key=key)
            result = OpenAI.openai_util(config, prompt)

            println("✅ [AI CALL] OpenAI responded successfully")
            println("📊 [AI CALL] Response length: $(length(result)) chars")
            return result

        elseif provider == "grok"
            # Usa chave fornecida ou do ENV
            key = isempty(api_key) ? get(ENV, "GROK_API_KEY", "") : api_key
            if isempty(key)
                error("Grok API key not found in ENV or provided")
            end

            config = Grok.GrokConfig(api_key=key)
            result = Grok.grok_util(config, prompt)

            println("✅ [AI CALL] Grok responded successfully")
            println("📊 [AI CALL] Response length: $(length(result)) chars")
            return result

        else
            error("Unknown AI provider: $provider. Use 'openai' or 'grok'")
        end

    catch e
        println("❌ [AI CALL] ERROR: $e")
        rethrow(e)
    end
end

# ========================================
# 📊 ENHANCED AI FEATURES (migrated from Python)
# ========================================

"""
    call_ai_with_retry(provider::String, prompt::String; max_retries::Int=3, api_key::String="") -> String

Enhanced AI call with retry logic and better error handling.
Migrated from backend/services/ai_service.py
"""
function call_ai_with_retry(
    provider::String,
    prompt::String;
    max_retries::Int = 3,
    api_key::String = ""
)
    for attempt in 1:max_retries
        try
            println("🔄 [AI RETRY] Attempt $attempt/$max_retries")
            return call_ai(provider, prompt; api_key=api_key)
        catch e
            if attempt == max_retries
                println("❌ [AI RETRY] All attempts failed")
                rethrow(e)
            else
                println("⚠️ [AI RETRY] Attempt $attempt failed, retrying... Error: $e")
                sleep(1.0 * attempt) # Exponential backoff
            end
        end
    end
end

"""
    call_ai_batch(provider::String, prompts::Vector{String}; api_key::String="") -> Vector{String}

Process multiple prompts in batch for efficiency.
"""
function call_ai_batch(
    provider::String,
    prompts::Vector{String};
    api_key::String = ""
)
    results = String[]

    println("📦 [AI BATCH] Processing $(length(prompts)) prompts")

    for (i, prompt) in enumerate(prompts)
        try
            println("🔄 [AI BATCH] Processing prompt $i/$(length(prompts))")
            result = call_ai(provider, prompt; api_key=api_key)
            push!(results, result)
        catch e
            println("❌ [AI BATCH] Failed prompt $i: $e")
            push!(results, "ERROR: $e")
        end

        # Rate limiting - small delay between calls
        if i < length(prompts)
            sleep(0.5)
        end
    end

    println("✅ [AI BATCH] Completed $(length(results)) results")
    return results
end

end