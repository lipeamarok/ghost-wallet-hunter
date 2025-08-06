import React from 'react';

// WebSocket Service for Real-time Investigation Updates
class WebSocketService {
  constructor() {
    this.ws = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 1000;
    this.listeners = new Map();
  }

  connect(url = 'ws://localhost:8001/api/v1/ws/investigations') {
    try {
      console.log('🔌 Connecting to WebSocket:', url);
      this.ws = new WebSocket(url);

      this.ws.onopen = (event) => {
        console.log('✅ WebSocket connected');
        this.reconnectAttempts = 0;
        this.emit('connected', event);
      };

      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          console.log('📨 WebSocket message:', data);
          this.emit('message', data);

          // Emit specific event types
          if (data.type) {
            this.emit(data.type, data);
          }
        } catch (error) {
          console.error('❌ Failed to parse WebSocket message:', error);
        }
      };

      this.ws.onclose = (event) => {
        console.log('🔌 WebSocket closed:', event.code, event.reason);
        this.emit('disconnected', event);

        // Auto-reconnect if not intentionally closed
        if (event.code !== 1000 && this.reconnectAttempts < this.maxReconnectAttempts) {
          this.attemptReconnect(url);
        }
      };

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket error:', error);
        this.emit('error', error);
      };

    } catch (error) {
      console.error('❌ WebSocket connection failed:', error);
      this.emit('error', error);
    }
  }

  attemptReconnect(url) {
    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    console.log(`🔄 Attempting reconnect ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`);

    setTimeout(() => {
      this.connect(url);
    }, delay);
  }

  disconnect() {
    if (this.ws) {
      this.ws.close(1000, 'Intentional disconnect');
      this.ws = null;
    }
  }

  send(data) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
      return true;
    } else {
      console.warn('⚠️ WebSocket not connected, cannot send data');
      return false;
    }
  }

  // Event system
  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event).push(callback);
  }

  off(event, callback) {
    if (this.listeners.has(event)) {
      const callbacks = this.listeners.get(event);
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  emit(event, data) {
    if (this.listeners.has(event)) {
      this.listeners.get(event).forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error(`❌ Error in WebSocket event listener for '${event}':`, error);
        }
      });
    }
  }

  // Investigation-specific methods
  subscribeToInvestigation(investigationId) {
    this.send({
      type: 'subscribe',
      investigation_id: investigationId
    });
  }

  unsubscribeFromInvestigation(investigationId) {
    this.send({
      type: 'unsubscribe',
      investigation_id: investigationId
    });
  }

  getConnectionStatus() {
    if (!this.ws) return 'disconnected';

    switch (this.ws.readyState) {
      case WebSocket.CONNECTING:
        return 'connecting';
      case WebSocket.OPEN:
        return 'connected';
      case WebSocket.CLOSING:
        return 'closing';
      case WebSocket.CLOSED:
        return 'disconnected';
      default:
        return 'unknown';
    }
  }
}

// Create singleton instance
const websocketService = new WebSocketService();

export default websocketService;

// React hook for using WebSocket in components
export const useWebSocket = () => {
  const [connectionStatus, setConnectionStatus] = React.useState('disconnected');
  const [lastMessage, setLastMessage] = React.useState(null);

  React.useEffect(() => {
    const handleConnection = () => setConnectionStatus('connected');
    const handleDisconnection = () => setConnectionStatus('disconnected');
    const handleMessage = (data) => setLastMessage(data);

    websocketService.on('connected', handleConnection);
    websocketService.on('disconnected', handleDisconnection);
    websocketService.on('message', handleMessage);

    // Update initial status
    setConnectionStatus(websocketService.getConnectionStatus());

    return () => {
      websocketService.off('connected', handleConnection);
      websocketService.off('disconnected', handleDisconnection);
      websocketService.off('message', handleMessage);
    };
  }, []);

  return {
    connectionStatus,
    lastMessage,
    send: websocketService.send.bind(websocketService),
    subscribe: websocketService.subscribeToInvestigation.bind(websocketService),
    unsubscribe: websocketService.unsubscribeFromInvestigation.bind(websocketService)
  };
};
