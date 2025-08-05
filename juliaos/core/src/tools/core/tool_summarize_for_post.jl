using DotEnv
DotEnv.load!()

using ..CommonTypes: ToolConfig, ToolMetadata, ToolSpecification
# using ...Resources: Gemini  # CHANGED TO OPENAI
using ..Resources: OpenAI

# OPENAI_API_KEY = ENV["OPENAI_API_KEY"]  # Using shared
OPENAI_MODEL = "gpt-3.5-turbo"

Base.@kwdef struct ToolSummarizeConfig <: ToolConfig
    api_key::String = get(ENV, "OPENAI_API_KEY", "")
    model_name::String = OPENAI_MODEL
end

function tool_summarize_for_post(cfg::ToolSummarizeConfig, task::Dict)::Dict{String,Any}
    if !haskey(task, "text")
        return Dict("success" => false, "error" => "Missing article text")
    end

    prompt = """
    You are AI news bot. Your task is to summarize the following news article into a Twitter post (max 250 characters), focusing on the key idea.

    Article:
    $(task["text"])
    """

    # OpenAI configuration (replacing Gemini)
    openai_cfg = Dict(
        "api_key" => cfg.api_key,
        "model" => cfg.model_name,
        "temperature" => 0.7,
        "max_tokens" => 100
    )

    try
        # Using OpenAI instead of Gemini
        post = OpenAI.openai_util(openai_cfg, prompt)
        return Dict("success" => true, "post_text" => strip(post))
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_SUMMARIZE_FOR_POST_METADATA = ToolMetadata(
    "summarize_for_post",
    "Summarizes a full news article into a short post for X(Twitter)"
)

const TOOL_SUMMARIZE_FOR_POST_SPECIFICATION = ToolSpecification(
    tool_summarize_for_post,
    ToolSummarizeConfig,
    TOOL_SUMMARIZE_FOR_POST_METADATA
)
