module MCPServer

using Dates

export register_tool, list_tools, invoke_tool, list_prompts, list_resources, get_server_status

const _TOOLS = Dict{String,Function}()
const _PROMPTS = Dict{String,String}()
const _RESOURCES = Dict{String,Dict{String,Any}}()

function register_tool(name::String, fn::Function; description::String="")
    _TOOLS[name] = fn
    return true
end

list_tools() = [Dict("name"=>k, "description"=>"", "type"=>"generic") for k in keys(_TOOLS)]
list_prompts() = [Dict("name"=>k, "content"=>v) for (k,v) in _PROMPTS]
list_resources() = [Dict("name"=>k, "meta"=>v) for (k,v) in _RESOURCES]

function invoke_tool(name::String, args::Dict=Dict())
    if haskey(_TOOLS, name)
        try
            result = _TOOLS[name](args)
            return Dict("ok"=>true, "result"=>result)
        catch e
            return Dict("ok"=>false, "error"=>string(e))
        end
    else
        return Dict("ok"=>false, "error"=>"tool_not_found")
    end
end

function get_server_status()
    return Dict(
        "status" => "operational",
        "tools_registered" => length(_TOOLS),
        "prompts" => length(_PROMPTS),
        "resources" => length(_RESOURCES),
        "timestamp" => now()
    )
end

# Simple default tools
register_tool("echo", args -> Dict("echo" => get(args, "message", "")))
register_tool("time_now", args -> Dict("now" => string(now())))

end # module MCPServer
