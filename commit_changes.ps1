# Script para commitar as mudanças do README

Write-Host "🔥 Iniciando commit das mudanças..." -ForegroundColor Green

# Verificar status atual
Write-Host "📊 Status atual do git:" -ForegroundColor Blue
git status

Write-Host "`n📦 Adicionando todos os arquivos..." -ForegroundColor Blue
git add .

Write-Host "`n📝 Commitando mudanças..." -ForegroundColor Blue
git commit -m "docs: Atualiza README com informações reais do projeto

- Remove claims inflados sobre A2A protocol inexistente
- Corrige contagem de detectivos de 8 para 7 reais
- Remove referências a backend Python inexistente  
- Atualiza stack para React + Julia + 7 detectivos
- Adiciona documentação honesta sobre status de desenvolvimento
- Remove falsa integração multi-chain (apenas Solana)
- Atualiza guia de instalação com requisitos reais
- Adiciona testes Julia para validação de componentes

Projeto agora reflete realidade: investigação Solana com 7 agentes
detective (Poirot, Marple, Spade, Marlowe, Dupin, Shadow, Raven)"

Write-Host "`n🚀 Push para o repositório..." -ForegroundColor Blue
git push origin main

Write-Host "`n✅ Commit completo!" -ForegroundColor Green
