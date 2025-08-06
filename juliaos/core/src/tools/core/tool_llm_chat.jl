# Safe environment loading - skip if not available
try
    using DotEnv
    if isfile("../../../../.env") || isfile("../../.env")
        DotEnv.load!()
    end
catch
    # Skip env loading during compilation
end

using ..Resources: OpenAI
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig


OPENAI_API_KEY = get(ENV, "OPENAI_API_KEY", "")
OPENAI_MODEL = "gpt-3.5-turbo"

Base.@kwdef struct ToolLLMChatConfig <: ToolConfig
    api_key::String = OPENAI_API_KEY
    model_name::String = OPENAI_MODEL
    temperature::Float64 = 0.7
    max_output_tokens::Int = 1024
end

function tool_llm_chat(cfg::ToolLLMChatConfig, task::Dict)
    openai_cfg = OpenAI.OpenAIConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )

    if !haskey(task, "prompt") || !(task["prompt"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'prompt' field")
    end

    try
        answer = OpenAI.openai_util(
            openai_cfg,
            task["prompt"]
        )
        return Dict("output" => answer, "success" => true)
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_LLM_CHAT_METADATA = ToolMetadata(
    "llm_chat",
    "Sends a prompt to the configured LLM provider and returns the response."
)

const TOOL_LLM_CHAT_SPECIFICATION = ToolSpecification(
    tool_llm_chat,
    ToolLLMChatConfig,
    TOOL_LLM_CHAT_METADATA
)
