"""
Analysis Module - Central Analysis Components

This module provides a centralized import point for all analysis components,
ensuring proper loading order and namespace management.
"""

module Analysis

# Import all analysis modules in correct order
include("TxTypes.jl")
include("TxParser.jl")
include("TxGraphBuilder.jl")
include("GraphMetrics.jl")
include("TaintPropagation.jl")
include("TaintCache.jl")
include("EntityClustering.jl")
include("IntegrationCatalog.jl")
include("IntegrationEvents.jl")
include("Explainability.jl")
include("FlowAttribution.jl")
include("InfluenceAnalysis.jl")
include("RiskEngine.jl")
include("RiskConfiguration.jl")
include("RegressionTesting.jl")

# Export core types
export TxEdge, TxGraph, GraphStats, PathEvidence

# F1 parser/graph/metrics
export parse_transaction, parse_transactions, validate_parsed_data
export build_graph, calculate_fan_in, calculate_fan_out, calculate_net_flow,
	   find_nodes_within_hops, calculate_graph_density, validate_graph
export generate_graph_stats, export_graph_stats_json, analyze_connectivity_patterns, calculate_performance_metrics

# F2 taint + cache
export TaintSeed, TaintResult, TaintConfig, DEFAULT_TAINT_CONFIG
export propagate_taint, calculate_taint_metrics, get_taint_for_address,
	   filter_high_taint_addresses, validate_taint_results
export CacheKey, CachedTaintResult, TaintCacheConfig, DEFAULT_CACHE_CONFIG,
	   get_cached_taint, cache_taint_results, cleanup_cache,
	   invalidate_cache_for_incidents, load_cache_from_disk, get_cache_stats

# F3 clustering + integration
export EntitySignal, EntityCluster, ClusteringConfig, DEFAULT_CLUSTERING_CONFIG,
	   analyze_fee_payer_patterns, analyze_fan_patterns, analyze_temporal_patterns,
	   build_entity_clusters, analyze_entity_clustering, validate_clustering_results
export ServiceEndpoint, IntegrationCatalog, CatalogConfig, DEFAULT_CATALOG_CONFIG,
	   get_catalog, lookup_service, get_services_by_type, check_integration_involvement,
	   analyze_integration_patterns, get_catalog_stats, update_catalog_from_sources
export IntegrationEvent, EventDetectionConfig, DEFAULT_EVENT_CONFIG,
	   detect_cash_out_events, detect_bridge_operations, detect_dex_interactions,
	   detect_suspicious_patterns, analyze_integration_events, validate_integration_events

# F4 explainability
export EvidencePath, PathSegment, ExplainabilityConfig, DEFAULT_EXPLAINABILITY_CONFIG,
	   dijkstra_k_shortest_paths, find_evidence_paths, analyze_evidence_paths,
	   validate_evidence_paths, convert_to_path_segments

# F5 flow attribution & influence
export analyze_flow_attribution
export analyze_network_influence

# F6 risk engine & configuration & regression
export default_risk_config, assess_wallet_risk
export RiskProfile, ConfigValidation, get_predefined_profiles, validate_risk_config,
	   load_risk_config, recommend_config_profile, export_config_to_json,
	   manage_risk_configuration
export ExploitTestCase, RegressionResult, RegressionSuiteResult,
	   get_historical_test_cases, run_regression_tests, validate_current_configuration

end # module Analysis
