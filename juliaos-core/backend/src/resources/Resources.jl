module Resources

include("types/Errors.jl")
include("types/Telegram.jl")
include("utils/Gemini.jl")
include("OpenAI.jl")
include("Grok.jl")

using .Telegram
using .Gemini
using .OpenAI
using .Grok

end