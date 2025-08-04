# 🧪 Ghost Wallet Hunter - Test Suite Documentation

## 📁 Tests Overview

Esta pasta contém todos os testes essenciais do Ghost Wallet Hunter, organizados por funcionalidade.

## 🔧 Core System Tests

### `test_basic.py`

- **Função**: Testes básicos do sistema
- **Objetivo**: Validar funcionamento fundamental da aplicação
- **Status**: ✅ Ativo

### `test_real_apis.py`

- **Função**: Testa integração com APIs reais (OpenAI, Solana RPC)
- **Objetivo**: Garantir que todas as APIs estão funcionando
- **Status**: ✅ Ativo

### `final_audit_no_mock.py`

- **Função**: Auditoria completa para garantir que não há dados mock no sistema
- **Objetivo**: Validar que apenas dados reais da blockchain são usados
- **Status**: ✅ Ativo - CRÍTICO

## 🕵️ Detective System Tests

### `test_legendary_squad.py`

- **Função**: Testa o esquadrão completo de detetives
- **Objetivo**: Validar funcionamento de todos os agentes IA
- **Status**: ✅ Ativo

### `test_contextual_recognition.py`

- **Função**: Testa reconhecimento contextual de tokens
- **Objetivo**: Validar que a IA reconhece tokens específicos
- **Status**: ✅ Ativo

## 🛡️ Security & Validation Tests

### `test_real_address_validator.py`

- **Função**: Testa validação de endereços de carteiras
- **Objetivo**: Garantir que apenas endereços reais são analisados
- **Status**: ✅ Ativo - CRÍTICO

### `test_false_positive_prevention.py`

- **Função**: Testa sistema de prevenção de falsos positivos
- **Objetivo**: Reduzir alertas incorretos
- **Status**: ✅ Ativo

## 🎯 Investigation Tests

### `test_real_investigation.py`

- **Função**: Testa investigação completa com dados reais
- **Objetivo**: Validar fluxo completo de análise
- **Status**: ✅ Ativo

### `test_risk_scoring_system.py`

- **Função**: Testa sistema de pontuação de risco
- **Objetivo**: Validar cálculos de risco
- **Status**: ✅ Ativo

## 🌐 Integration Tests

### `test_frontend_integration.py`

- **Função**: Testa integração entre frontend e backend
- **Objetivo**: Garantir comunicação adequada
- **Status**: ✅ Ativo

### `test_integration.py`

- **Função**: Testes de integração geral do sistema
- **Objetivo**: Validar funcionamento end-to-end
- **Status**: ✅ Ativo

## 🔧 Utilities

### `wallet_address_validator.py`

- **Função**: Utilitário para validar endereços Solana
- **Objetivo**: Ferramenta standalone para validação
- **Status**: ✅ Ativo

## 🏃‍♂️ Como Executar

### Teste Individual

```bash
cd backend
python tests/test_basic.py
```

### Auditoria Completa (RECOMENDADO)

```bash
cd backend
python tests/final_audit_no_mock.py
```

### Validar Endereço

```bash
cd backend
python tests/wallet_address_validator.py "ENDEREÇO_SOLANA"
```

## ✅ Testes Críticos (Executar Sempre)

1. **`final_audit_no_mock.py`** - Garantir que não há dados falsos
2. **`test_real_address_validator.py`** - Validar segurança de endereços
3. **`test_real_apis.py`** - Verificar conectividade das APIs

## 🗑️ Testes Removidos

Os seguintes testes foram removidos por serem obsoletos:

- `test_fake_address.py` - Redundante com validador
- `test_real_data.py` - Incorporado na auditoria final
- `test_detective_ai_integration.py` - Incorporado nos testes do squad
- `test_ai_integration.py` - Redundante com test_real_apis
- `test_contextual_simple.py` - Versão simplificada removida
- `demonstracao_*.py` - Demonstrações obsoletas
- `teste_*.py` - Testes em português obsoletos
