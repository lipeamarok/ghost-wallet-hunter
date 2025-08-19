module Tools

export TOOL_REGISTRY

include("../agents/CommonTypes.jl") # ensure CommonTypes available before referencing
include("core/tool_example_adder.jl")
include("core/tool_ping.jl")
include("core/tool_llm_chat.jl")
include("core/tool_write_blog.jl")
# include("core/tool_post_to_x.jl")  # DISABLED - PyCall issue in container
include("telegram/tool_ban_user.jl")
include("telegram/tool_detect_swearing.jl")
include("telegram/tool_send_message.jl")
include("core/tool_scrape_article_text.jl")
include("core/tool_summarize_for_post.jl")

# Ghost Wallet Hunter tools
include("ghost_wallet_hunter/tool_analyze_wallet.jl")
include("ghost_wallet_hunter/tool_check_blacklist.jl")
include("ghost_wallet_hunter/tool_risk_assessment.jl")
include("ghost_wallet_hunter/tool_detective_swarm.jl")

using .CommonTypes: ToolSpecification

const TOOL_REGISTRY = Dict{String, ToolSpecification}()

function register_tool(tool_spec::ToolSpecification)
    tool_name = tool_spec.metadata.name
    if haskey(TOOL_REGISTRY, tool_name)
        error("Tool with name '$tool_name' is already registered.")
    end
    TOOL_REGISTRY[tool_name] = tool_spec
end

# All tools to be used by agents must be registered here:

register_tool(TOOL_BLOG_WRITER_SPECIFICATION)
# register_tool(TOOL_POST_TO_X_SPECIFICATION)  # DISABLED - PyCall issue in container
register_tool(TOOL_EXAMPLE_ADDER_SPECIFICATION)
register_tool(TOOL_LLM_CHAT_SPECIFICATION)
register_tool(TOOL_PING_SPECIFICATION)
register_tool(TOOL_BAN_USER_SPECIFICATION)
register_tool(TOOL_DETECT_SWEAR_SPECIFICATION)
register_tool(TOOL_SEND_MESSAGE_SPECIFICATION)
register_tool(TOOL_SCRAPE_ARTICLE_TEXT_SPECIFICATION)
register_tool(TOOL_SUMMARIZE_FOR_POST_SPECIFICATION)

# Ghost Wallet Hunter tools registration
register_tool(TOOL_ANALYZE_WALLET_SPECIFICATION)
register_tool(TOOL_CHECK_BLACKLIST_SPECIFICATION)
register_tool(TOOL_RISK_ASSESSMENT_SPECIFICATION)
register_tool(TOOL_DETECTIVE_SWARM_SPECIFICATION)

end