"""
A2A Types Module - Pydantic v1 Compatible
=========================================

Tipos de dados para protocolo Agent-to-Agent.
Compatível com Pydantic v1 para integração com JuliaOS.
"""

from pydantic import BaseModel
from typing import Dict, Any, List, Optional
import uuid


class MessageSendParams(BaseModel):
    """Parâmetros para envio de mensagem A2A"""
    message: Dict[str, Any]
    inputMode: str = "text"


class SendMessageRequest(BaseModel):
    """Request para envio de mensagem A2A"""
    id: str
    params: MessageSendParams

    @classmethod
    def create(cls, message_content: Dict[str, Any], input_mode: str = "text") -> 'SendMessageRequest':
        """Cria request com ID automático"""
        return cls(
            id=str(uuid.uuid4()),
            params=MessageSendParams(
                message=message_content,
                inputMode=input_mode
            )
        )


class MessagePart(BaseModel):
    """Parte de uma mensagem"""
    kind: str = "text"
    text: str


class UserMessage(BaseModel):
    """Mensagem do usuário"""
    role: str = "user"
    parts: List[MessagePart]
    messageId: str

    @classmethod
    def create(cls, text_content: str) -> 'UserMessage':
        """Cria mensagem do usuário"""
        return cls(
            role="user",
            parts=[MessagePart(kind="text", text=text_content)],
            messageId=uuid.uuid4().hex
        )


class DataPart(BaseModel):
    """Parte de dados para execução"""
    kind: str = "data"
    content: Dict[str, Any]


class AgentSkill(BaseModel):
    """Habilidade de um agente"""
    id: str
    name: str
    description: str
    parameters: Optional[Dict[str, Any]] = None


class AgentCapabilities(BaseModel):
    """Capacidades de um agente"""
    streaming: bool = False
    collaborative: bool = True
    specialized: bool = True


class AgentCard(BaseModel):
    """Cartão de apresentação de um agente"""
    agent_id: str
    name: str
    endpoint: str
    description: Optional[str] = None
    version: Optional[str] = "1.0.0"
    url: Optional[str] = None
    capabilities: Optional[AgentCapabilities] = None
    skills: Optional[List[AgentSkill]] = None
    defaultInputModes: Optional[List[str]] = None
    defaultOutputModes: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None


class A2AProtocolMessage(BaseModel):
    """Mensagem padrão do protocolo A2A"""
    from_agent: str
    to_agent: str
    message_type: str
    content: Dict[str, Any]
    timestamp: str
    message_id: str


class A2AProtocolResponse(BaseModel):
    """Resposta padrão do protocolo A2A"""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    timestamp: str
    agent_id: str


class InvestigationRequest(BaseModel):
    """Request para investigação blockchain"""
    target_wallet: str
    investigation_type: str
    detective_id: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None


class InvestigationResponse(BaseModel):
    """Resposta de investigação"""
    investigation_id: str
    detective_id: str
    detective_name: str
    target_wallet: str
    status: str
    findings: Optional[Dict[str, Any]] = None
    created_at: str


# Aliases para compatibilidade
A2AMessage = A2AProtocolMessage
A2AResponse = A2AProtocolResponse