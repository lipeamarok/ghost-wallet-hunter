#!/usr/bin/env julia

"""
Ghost Wallet Hunter - Servidor Julia
Script principal para iniciar o servidor Julia do projeto
"""

using Pkg

println("🔧 Configurando ambiente Julia para Ghost Wallet Hunter...")

# Lista de pacotes necessários
required_packages = [
    "HTTP",
    "JSON3",
    "Dates",
    "UUIDs"
]

println("📦 Verificando dependências...")

# Instalar pacotes se necessário
for package in required_packages
    try
        eval(Meta.parse("using $package"))
        println("  ✅ $package: OK")
    catch
        println("  📥 Instalando $package...")
        Pkg.add(package)
        println("  ✅ $package: Instalado")
    end
end

println("\n🚀 Todas as dependências prontas!")

# Importar depois de instalar
using HTTP
using JSON3
using Dates
using UUIDs

# Load DetectiveAgents module
println("🕵️ Carregando Detective Squad...")
try
    include("src/agents/DetectiveAgents.jl")
    using .DetectiveAgents
    println("  ✅ Detective Squad: Loaded with $(length(get_all_detectives())) detectives")
catch e
    println("  ⚠️ Detective Squad error: $e")
end

println("🎯 Iniciando servidor Ghost Wallet Hunter...")
println("=" ^ 50)

# Configurações
const PORT = 8052
const HOST = "0.0.0.0"

println("🚀 Iniciando Ghost Wallet Hunter - Servidor Julia")
println("📍 Host: $HOST")
println("🔌 Porta: $PORT")

# Middleware CORS
function cors_middleware(handler)
    return function(req::HTTP.Request)
        if req.method == "OPTIONS"
            return HTTP.Response(200, [
                "Access-Control-Allow-Origin" => "*",
                "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers" => "Content-Type, Authorization"
            ])
        end

        response = handler(req)

        # Adicionar headers CORS a todas as respostas
        HTTP.setheader(response, "Access-Control-Allow-Origin" => "*")
        HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS")
        HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type, Authorization")

        return response
    end
end

# Handler principal
function handle_request(req::HTTP.Request)
    try
        method = req.method
        path = req.target

        println("📥 $method $path")

        # Rota de health check
        if path == "/health" || path == "/api/health"
            return HTTP.Response(200,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "status" => "ok",
                    "service" => "Ghost Wallet Hunter Julia Server",
                    "port" => PORT,
                    "timestamp" => string(now()),
                    "version" => "1.0.0"
                ))
            )
        end

        # Rota de teste
        if path == "/api/v1/test/hello"
            return HTTP.Response(200,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "message" => "Hello from Julia Server!",
                    "service" => "Ghost Wallet Hunter",
                    "timestamp" => string(now())
                ))
            )
        end

        # Rota de agentes
        if path == "/api/v1/agents"
            try
                # Use consolidated DetectiveAgents module
                agents = get_all_detectives()

                return HTTP.Response(200,
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict(
                        "status" => "success",
                        "agents" => agents,
                        "count" => length(agents),
                        "source" => "consolidated_julia_detectives"
                    ))
                )
            catch e
                # Fallback to static list if module fails
                agents = [
                    Dict("id" => "poirot", "name" => "Detective Hercule Poirot", "status" => "active"),
                    Dict("id" => "marple", "name" => "Detective Miss Marple", "status" => "active"),
                    Dict("id" => "spade", "name" => "Detective Sam Spade", "status" => "active"),
                    Dict("id" => "shadow", "name" => "Detective The Shadow", "status" => "active"),
                    Dict("id" => "raven", "name" => "Detective Edgar Raven", "status" => "active")
                ]

                return HTTP.Response(200,
                    ["Content-Type" => "application/json"],
                    JSON3.write(Dict(
                        "status" => "success",
                        "agents" => agents,
                        "count" => length(agents),
                        "source" => "fallback_static_list",
                        "error" => string(e)
                    ))
                )
            end
        end

        # Rota para executar ferramenta - REAL EXECUTION
        if startswith(path, "/api/v1/tools/")
            tool_name = replace(path, "/api/v1/tools/" => "")

            # TODO: Integrate with Tools.jl module for real execution
            return HTTP.Response(200,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "status" => "success",
                    "message" => "Tool execution endpoint ready for real implementation",
                    "tool" => tool_name,
                    "path" => path,
                    "timestamp" => string(now()),
                    "note" => "Connect to Tools.jl module for actual execution"
                ))
            )
        end

        # 404 para outras rotas
        return HTTP.Response(404,
            ["Content-Type" => "application/json"],
            JSON3.write(Dict(
                "error" => "Route not found",
                "path" => path,
                "method" => method
            ))
        )

    catch e
        println("❌ Erro no handler: $e")
        return HTTP.Response(500,
            ["Content-Type" => "application/json"],
            JSON3.write(Dict(
                "error" => "Internal server error",
                "message" => string(e)
            ))
        )
    end
end

# Iniciar servidor
function start_server()
    try
        println("\n🌐 Rotas disponíveis:")
        println("  • GET  /health                 - Health check")
        println("  • GET  /api/health             - Health check (alt)")
        println("  • GET  /api/v1/test/hello      - Teste básico")
        println("  • GET  /api/v1/agents          - Listar agentes")
        println("  • POST /api/v1/tools/*         - Executar ferramentas")

        println("\n🚀 Iniciando servidor HTTP...")

        # Criar servidor com middleware CORS
        router = cors_middleware(handle_request)

        server = HTTP.serve(router, HOST, PORT; verbose=false)

        println("✅ Servidor Julia ativo em http://$HOST:$PORT")
        println("🔗 Teste: http://localhost:$PORT/health")
        println("🚀 Servidor pronto! Pressione Ctrl+C para parar.")

        # Manter servidor rodando
        wait(server)

    catch e
        if isa(e, InterruptException)
            println("\n⏹️ Servidor interrompido pelo usuário")
        else
            println("❌ Erro fatal: $e")
            rethrow(e)
        end
    finally
        println("🔒 Encerrando servidor...")
    end
end

# Iniciar servidor
start_server()
