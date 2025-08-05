using DotEnv
DotEnv.load!()

# using ...Resources: Gemini  # CHANGED TO OPENAI
using ..Resources: OpenAI
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig


# OPENAI_API_KEY = ENV["OPENAI_API_KEY"]  # Using shared
OPENAI_MODEL = "gpt-3.5-turbo"

Base.@kwdef struct ToolBlogWriterConfig <: ToolConfig
    api_key::String = get(ENV, "OPENAI_API_KEY", "")
    model_name::String = OPENAI_MODEL
    temperature::Float64 = 0.7
    max_tokens::Int = 1024  # Changed from max_output_tokens
end

const ALLOWED_FORMATS = Set(["plain", "markdown", "html"])
MAX_ATTEMPTS = 3

"""
    tool_write_blog(cfg::ToolBlogWriterConfig, task::Dict) -> Dict{String, Any}

Generates a structured blog post based on a given topic and optional settings.

# Arguments
- `cfg::ToolBlogWriterConfig`: Tool config.
- `task::Dict`: A dictionary with blog generation instructions.
    - Required key:
        - "title": The topic of the blog post.
    - Optional keys:
        - "tone": Tone of the blog post (e.g., "neutral", "formal", "casual", "humorous"). Default: "neutral".
        - "max_characters_amount": Maximum allowed character length for the post. Default: 500.
        - "output_format": Format of the returned content. One of: "plain", "markdown", "html". Default: "plain".

# Returns
A dictionary with the execution result.
"""
function tool_write_blog(cfg::ToolBlogWriterConfig, task::Dict)
    if !haskey(task, "title") || !(task["title"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'topic'")
    elseif haskey(task, "output_format") && lowercase(task["output_format"]) ∉ ALLOWED_FORMATS
        return Dict("success" => false, "error" => "Invalid 'output_format'. Allowed formats: $(join(ALLOWED_FORMATS, ", "))")
    end

    title = task["title"]
    tone = get(task, "tone", "neutral")
    max_characters_amount = get(task, "max_characters_amount", 500)
    output_format = get(task, "output_format", "plain")

    prompt = """
    Write a blog post on the topic "$title" in a $tone tone.
    The post must contain maximun $(max_characters_amount) characters.
    Make it engaging and well-structured.
    Return the output in the following format: $output_format.
    """

    # OpenAI configuration (replacing Gemini)
    openai_cfg = Dict(
        "api_key" => cfg.api_key,
        "model" => cfg.model_name,
        "temperature" => cfg.temperature,
        "max_tokens" => cfg.max_tokens
    )

    for _ in 1:MAX_ATTEMPTS
        try
            # Using OpenAI instead of Gemini
            answer = OpenAI.openai_util(openai_cfg, prompt)

            if length(answer) ≤ max_characters_amount
                return Dict("output" => answer, "success" => true)
            end

        catch e
            return Dict("success" => false, "error" => string(e))
        end
    end

    return Dict(
        "success" => false, "error" => "Failed to generate a blog post within $(max_characters_amount) characters after $MAX_ATTEMPTS attempts."
    )
end

const TOOL_BLOG_WRITER_METADATA = ToolMetadata(
    "write_blog",
    "Generates a structured blog post based on a given topic and optional settings."
)

const TOOL_BLOG_WRITER_SPECIFICATION = ToolSpecification(
    tool_write_blog,
    ToolBlogWriterConfig,
    TOOL_BLOG_WRITER_METADATA
)
