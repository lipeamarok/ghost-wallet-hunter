#!/usr/bin/env julia

"""
Quick Port Bind - Inicia servidor HTTP básico IMEDIATAMENTE
para sinalizar ao Render que a porta está ativa, enquanto o Julia compila
"""

using Sockets

# Porta do Render ou 8052 como fallback
const PORT = parse(Int, get(ENV, "PORT", "8052"))

println("🚀 [QUICK BIND] Iniciando bind imediato na porta $PORT...")

# Servidor TCP básico para sinalizar porta ativa
server = listen(PORT)

println("✅ [QUICK BIND] Porta $PORT ATIVA - Render detectará agora!")
println("🔄 [JULIA INIT] Iniciando carregamento completo do sistema...")

# Aceitar 1 conexão para responder ao health check do Render
@async begin
    try
        conn = accept(server)
        write(conn, "HTTP/1.1 200 OK\r\n\r\n{\"status\":\"initializing\",\"message\":\"Julia system loading...\"}")
        close(conn)
    catch e
        println("⚠️  [QUICK BIND] Erro na conexão inicial: $e")
    end
end

# Fechar servidor básico após 30 segundos (suficiente para Render detectar)
Timer(30.0) do t
    try
        close(server)
        println("🔄 [QUICK BIND] Servidor básico fechado - passando para sistema principal")
    catch
    end
end

# Agora carrega o sistema completo
println("📦 [JULIA INIT] Carregando sistema Julia completo...")
include("start_julia_server.jl")
