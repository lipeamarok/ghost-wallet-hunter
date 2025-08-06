# Safe environment loading utility
# This file provides a safe way to load environment variables without crashing compilation

using DotEnv

function safe_load_env()
    try
        if isfile(".env")
            DotEnv.load!()
        end
    catch e
        # Silently ignore env loading errors during compilation
        @debug "Environment loading skipped: $e"
    end
end

# Safe environment variable getter
function safe_get_env(key::String, default::String="")
    return get(ENV, key, default)
end

export safe_load_env, safe_get_env
