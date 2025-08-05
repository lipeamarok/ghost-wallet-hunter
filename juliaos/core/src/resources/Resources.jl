module Resources

include("types/Errors.jl")
include("types/Telegram.jl")
include("OpenAI.jl")
include("Grok.jl")

using .Telegram
using .OpenAI
using .Grok

end