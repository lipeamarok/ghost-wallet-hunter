module JuliaOSServer

# Include the main JuliaOS module
include("JuliaOS.jl")
using .JuliaOS

# Include API server specifically
include("api/JuliaOSV1Server.jl")
using .JuliaOSV1Server

# Export everything needed for server operation
export JuliaOS, JuliaOSV1Server

end
