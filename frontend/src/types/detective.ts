// Detective Squad Types
export interface Detective {
  name: string;
  code_name: string;
  specialty: string;
  status: 'active' | 'busy' | 'offline';
  cases_solved: number;
  success_rate: number;
  motto: string;
  location: string;
}

export interface SquadStatus {
  total_detectives: number;
  active_detectives: number;
  squad_health: 'excellent' | 'good' | 'degraded' | 'critical';
  detectives: Detective[];
  last_updated: string;
}

// Investigation Types
export interface InvestigationRequest {
  wallet_address: string;
  depth?: number;
  include_metadata?: boolean;
  budget_limit?: number;
  user_id?: string;
}

export interface DetectiveFindings {
  detective_name: string;
  analysis: string;
  confidence: number;
  risk_score: number;
  key_findings: string[];
  anomalies_detected: string[];
  recommendations: string[];
  metadata: {
    analysis_time: number;
    tokens_used: number;
    cost: number;
  };
}

export interface InvestigationResult {
  investigation_id: string;
  wallet_address: string;
  squad_findings: DetectiveFindings[];
  overall_risk_score: number;
  consensus_analysis: string;
  investigation_summary: {
    total_detectives: number;
    analysis_time: number;
    total_cost: number;
    confidence_level: number;
  };
  created_at: string;
}

// Cost Management Types
export interface CostUsage {
  user_id: string;
  total_cost: number;
  daily_cost: number;
  requests_today: number;
  monthly_cost: number;
  requests_this_month: number;
  limits: {
    daily_budget: number;
    monthly_budget: number;
    requests_per_minute: number;
    requests_per_hour: number;
    requests_per_day: number;
  };
  remaining: {
    daily_budget: number;
    monthly_budget: number;
    requests_today: number;
  };
}

export interface ProviderCost {
  provider: string;
  total_cost: number;
  total_requests: number;
  average_cost_per_request: number;
  last_request: string;
  status: 'active' | 'fallback' | 'disabled';
}

export interface CostDashboard {
  total_cost: number;
  total_requests: number;
  active_users: number;
  cost_by_provider: ProviderCost[];
  recent_investigations: {
    investigation_id: string;
    wallet_address: string;
    cost: number;
    detectives_used: number;
    timestamp: string;
  }[];
  cost_trends: {
    date: string;
    cost: number;
    requests: number;
  }[];
}

// API Response Types
export interface APIResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  timestamp: string;
}

export interface ErrorResponse {
  success: false;
  error: string;
  detail?: string;
  timestamp: string;
}

// Health Check Types
export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  version: string;
  uptime: number;
  database: {
    status: 'connected' | 'disconnected';
    response_time: number;
  };
  ai_providers: {
    openai: 'available' | 'unavailable' | 'rate_limited';
    grok: 'available' | 'unavailable' | 'rate_limited';
  };
  detectives: {
    active: number;
    total: number;
  };
}

// UI State Types
export interface AnalysisState {
  isLoading: boolean;
  currentStep: number;
  progress: number;
  error: string | null;
  result: InvestigationResult | null;
}

export interface DetectiveCardProps {
  detective: Detective;
  onSelect?: (detective: Detective) => void;
  isSelected?: boolean;
  showStats?: boolean;
}

export interface ProgressStepProps {
  step: {
    id: number;
    name: string;
    description: string;
    status: 'pending' | 'active' | 'completed' | 'error';
  };
  isActive: boolean;
}

// Form Types
export interface WalletAnalysisForm {
  walletAddress: string;
  analysisDepth: number;
  includeMetadata: boolean;
  budgetLimit: number;
  selectedDetectives: string[];
}

export interface CostLimitsForm {
  dailyBudget: number;
  monthlyBudget: number;
  requestsPerMinute: number;
  requestsPerHour: number;
  requestsPerDay: number;
}

// Chart Data Types
export interface ChartDataPoint {
  date: string;
  cost: number;
  requests: number;
  label?: string;
}

export interface PieChartData {
  name: string;
  value: number;
  color: string;
}

// Notification Types
export interface NotificationMessage {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
}
