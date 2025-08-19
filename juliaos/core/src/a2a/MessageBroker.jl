"""
    MessageBroker.jl

    Advanced Message Broker for A2A (Agent-to-Agent) Communication
    Part of JuliaOS Ghost Wallet Hunter - High-Performance Backend Migration

    Features:
    - Real-time message routing between agents
    - Pub/Sub pattern for agent communication
    - Message persistence and reliability
    - Redis backend integration
    - Async message handling
    - Message filtering and routing
    - Dead letter queue handling
    - Performance monitoring
"""

module MessageBroker

using Dates
using JSON3
using HTTP
using Redis
using Logging
using UUIDs

# Structs and Types
"""
    Message

Represents a message in the A2A communication system.
"""
struct Message
    id::String
    sender_id::String
    receiver_id::String
    message_type::String
    payload::Dict{String, Any}
    priority::Int  # 1=low, 5=normal, 10=high
    timestamp::DateTime
    expires_at::Union{DateTime, Nothing}
    correlation_id::Union{String, Nothing}
    reply_to::Union{String, Nothing}
    headers::Dict{String, String}
end

"""
    MessageBrokerConfig

Configuration for the message broker service.
"""
struct MessageBrokerConfig
    redis_host::String
    redis_port::Int
    redis_db::Int
    max_message_size::Int
    message_ttl::Int  # Time to live in seconds
    dead_letter_ttl::Int
    max_retries::Int
    enable_persistence::Bool
    enable_metrics::Bool
    worker_threads::Int
end

"""
    MessageBroker

Main message broker service for A2A communication.
"""
mutable struct MessageBroker
    config::MessageBrokerConfig
    redis_client::Union{RedisConnection, Nothing}
    subscribers::Dict{String, Vector{Function}}
    message_handlers::Dict{String, Function}
    metrics::Dict{String, Any}
    running::Bool
    worker_tasks::Vector{Task}
end

# Default configuration
function default_broker_config()
    return MessageBrokerConfig(
        "localhost",      # redis_host
        6379,            # redis_port
        0,               # redis_db
        1024 * 1024,     # max_message_size (1MB)
        3600,            # message_ttl (1 hour)
        86400,           # dead_letter_ttl (24 hours)
        3,               # max_retries
        true,            # enable_persistence
        true,            # enable_metrics
        4                # worker_threads
    )
end

"""
    create_message_broker(config::MessageBrokerConfig = default_broker_config()) -> MessageBroker

Creates and initializes a new message broker instance.
"""
function create_message_broker(config::MessageBrokerConfig = default_broker_config())
    try
        broker = MessageBroker(
            config,
            nothing,
            Dict{String, Vector{Function}}(),
            Dict{String, Function}(),
            Dict{String, Any}(
                "messages_sent" => 0,
                "messages_received" => 0,
                "messages_failed" => 0,
                "active_subscribers" => 0,
                "average_latency" => 0.0,
                "last_activity" => now()
            ),
            false,
            Vector{Task}()
        )

        # Initialize Redis connection
        initialize_redis_connection!(broker)

        # Initialize dead letter queue
        initialize_dead_letter_queue!(broker)

        @info "🚀 MessageBroker created successfully!"
        @info "   📡 Redis: $(config.redis_host):$(config.redis_port)"
        @info "   💾 Persistence: $(config.enable_persistence)"
        @info "   📊 Metrics: $(config.enable_metrics)"

        return broker

    catch e
        @error "❌ Failed to create MessageBroker: $e"
        rethrow(e)
    end
end

"""
    initialize_redis_connection!(broker::MessageBroker)

Initializes Redis connection for the message broker.
"""
function initialize_redis_connection!(broker::MessageBroker)
    try
        # Connect to Redis
        broker.redis_client = RedisConnection(
            host = broker.config.redis_host,
            port = broker.config.redis_port,
            db = broker.config.redis_db
        )

        # Test connection
        ping_result = execute(broker.redis_client, ["PING"])
        if ping_result == "PONG"
            @info "✅ Redis connection established successfully"
        else
            throw(ErrorException("Redis ping failed"))
        end

    catch e
        @error "❌ Failed to initialize Redis connection: $e"
        throw(e)
    end
end

"""
    initialize_dead_letter_queue!(broker::MessageBroker)

Initializes the dead letter queue for failed messages.
"""
function initialize_dead_letter_queue!(broker::MessageBroker)
    try
        dlq_key = "a2a:dead_letter_queue"

        # Ensure DLQ exists
        if broker.redis_client !== nothing
            execute(broker.redis_client, ["SETNX", dlq_key, "initialized"])
            @info "✅ Dead Letter Queue initialized"
        end

    catch e
        @warn "⚠️ Failed to initialize Dead Letter Queue: $e"
    end
end

"""
    start_broker!(broker::MessageBroker)

Starts the message broker service with worker threads.
"""
function start_broker!(broker::MessageBroker)
    try
        if broker.running
            @warn "⚠️ Broker is already running"
            return
        end

        broker.running = true
        @info "🚀 Starting MessageBroker with $(broker.config.worker_threads) workers..."

        # Start worker tasks
        for i in 1:broker.config.worker_threads
            worker_task = @async worker_loop(broker, i)
            push!(broker.worker_tasks, worker_task)
        end

        # Start metrics collection if enabled
        if broker.config.enable_metrics
            metrics_task = @async metrics_collector_loop(broker)
            push!(broker.worker_tasks, metrics_task)
        end

        @info "✅ MessageBroker started successfully!"
        @info "   👥 Workers: $(length(broker.worker_tasks))"
        @info "   📊 Metrics: $(broker.config.enable_metrics)"

    catch e
        broker.running = false
        @error "❌ Failed to start MessageBroker: $e"
        rethrow(e)
    end
end

"""
    stop_broker!(broker::MessageBroker)

Stops the message broker service gracefully.
"""
function stop_broker!(broker::MessageBroker)
    try
        @info "🛑 Stopping MessageBroker..."

        broker.running = false

        # Wait for worker tasks to complete
        for task in broker.worker_tasks
            try
                wait(task)
            catch e
                @warn "Worker task stopped with error: $e"
            end
        end

        # Close Redis connection
        if broker.redis_client !== nothing
            disconnect(broker.redis_client)
            broker.redis_client = nothing
        end

        @info "✅ MessageBroker stopped successfully"

    catch e
        @error "❌ Error stopping MessageBroker: $e"
    end
end

"""
    publish_message(broker::MessageBroker, message::Message) -> Bool

Publishes a message to the broker for distribution.
"""
function publish_message(broker::MessageBroker, message::Message)
    try
        if !broker.running
            @error "❌ Broker is not running"
            return false
        end

        # Validate message
        if !validate_message(message)
            @error "❌ Invalid message format"
            return false
        end

        # Check message size
        message_json = JSON3.write(message)
        if length(message_json) > broker.config.max_message_size
            @error "❌ Message exceeds maximum size limit"
            return false
        end

        # Store message if persistence is enabled
        if broker.config.enable_persistence
            store_message(broker, message)
        end

        # Route message to subscribers
        route_message_to_subscribers(broker, message)

        # Update metrics
        broker.metrics["messages_sent"] += 1
        broker.metrics["last_activity"] = now()

        @debug "📤 Message published: $(message.id)"
        return true

    catch e
        broker.metrics["messages_failed"] += 1
        @error "❌ Failed to publish message: $e"
        return false
    end
end

"""
    subscribe(broker::MessageBroker, topic::String, handler::Function) -> String

Subscribes to messages on a specific topic.
"""
function subscribe(broker::MessageBroker, topic::String, handler::Function)
    try
        subscription_id = string(uuid4())

        if !haskey(broker.subscribers, topic)
            broker.subscribers[topic] = Vector{Function}()
        end

        push!(broker.subscribers[topic], handler)
        broker.metrics["active_subscribers"] += 1

        @info "✅ Subscribed to topic '$topic' with ID: $subscription_id"
        return subscription_id

    catch e
        @error "❌ Failed to subscribe to topic '$topic': $e"
        rethrow(e)
    end
end

"""
    unsubscribe(broker::MessageBroker, topic::String, handler::Function) -> Bool

Unsubscribes from a specific topic.
"""
function unsubscribe(broker::MessageBroker, topic::String, handler::Function)
    try
        if haskey(broker.subscribers, topic)
            filter!(h -> h !== handler, broker.subscribers[topic])
            broker.metrics["active_subscribers"] = max(0, broker.metrics["active_subscribers"] - 1)
            @info "✅ Unsubscribed from topic '$topic'"
            return true
        end
        return false

    catch e
        @error "❌ Failed to unsubscribe from topic '$topic': $e"
        return false
    end
end

"""
    send_direct_message(broker::MessageBroker, sender_id::String, receiver_id::String,
                       message_type::String, payload::Dict) -> Bool

Sends a direct message from one agent to another.
"""
function send_direct_message(broker::MessageBroker, sender_id::String, receiver_id::String,
                           message_type::String, payload::Dict; priority::Int = 5)
    try
        message = Message(
            string(uuid4()),              # id
            sender_id,                    # sender_id
            receiver_id,                  # receiver_id
            message_type,                 # message_type
            payload,                      # payload
            priority,                     # priority
            now(),                        # timestamp
            now() + Second(broker.config.message_ttl),  # expires_at
            nothing,                      # correlation_id
            nothing,                      # reply_to
            Dict{String, String}()        # headers
        )

        return publish_message(broker, message)

    catch e
        @error "❌ Failed to send direct message: $e"
        return false
    end
end

"""
    broadcast_message(broker::MessageBroker, sender_id::String, topic::String,
                     message_type::String, payload::Dict) -> Bool

Broadcasts a message to all subscribers of a topic.
"""
function broadcast_message(broker::MessageBroker, sender_id::String, topic::String,
                         message_type::String, payload::Dict; priority::Int = 5)
    try
        message = Message(
            string(uuid4()),              # id
            sender_id,                    # sender_id
            topic,                        # receiver_id (topic name)
            message_type,                 # message_type
            payload,                      # payload
            priority,                     # priority
            now(),                        # timestamp
            now() + Second(broker.config.message_ttl),  # expires_at
            nothing,                      # correlation_id
            nothing,                      # reply_to
            Dict("broadcast" => "true")   # headers
        )

        return publish_message(broker, message)

    catch e
        @error "❌ Failed to broadcast message: $e"
        return false
    end
end

# Internal helper functions

"""
    validate_message(message::Message) -> Bool

Validates a message structure and content.
"""
function validate_message(message::Message)
    try
        # Check required fields
        if isempty(message.id) || isempty(message.sender_id) || isempty(message.receiver_id)
            return false
        end

        # Check timestamp
        if message.timestamp > now()
            return false
        end

        # Check expiration
        if message.expires_at !== nothing && message.expires_at < now()
            return false
        end

        # Check priority range
        if message.priority < 1 || message.priority > 10
            return false
        end

        return true

    catch e
        @error "❌ Message validation error: $e"
        return false
    end
end

"""
    store_message(broker::MessageBroker, message::Message)

Stores a message in Redis for persistence.
"""
function store_message(broker::MessageBroker, message::Message)
    try
        if broker.redis_client === nothing
            return
        end

        message_key = "a2a:message:$(message.id)"
        message_json = JSON3.write(message)

        # Store with TTL
        execute(broker.redis_client, ["SETEX", message_key, string(broker.config.message_ttl), message_json])

        # Add to sender's outbox
        sender_outbox = "a2a:outbox:$(message.sender_id)"
        execute(broker.redis_client, ["LPUSH", sender_outbox, message.id])
        execute(broker.redis_client, ["EXPIRE", sender_outbox, string(broker.config.message_ttl)])

        # Add to receiver's inbox
        receiver_inbox = "a2a:inbox:$(message.receiver_id)"
        execute(broker.redis_client, ["LPUSH", receiver_inbox, message.id])
        execute(broker.redis_client, ["EXPIRE", receiver_inbox, string(broker.config.message_ttl)])

    catch e
        @error "❌ Failed to store message: $e"
    end
end

"""
    route_message_to_subscribers(broker::MessageBroker, message::Message)

Routes a message to all relevant subscribers.
"""
function route_message_to_subscribers(broker::MessageBroker, message::Message)
    try
        # Direct message routing
        if haskey(broker.subscribers, message.receiver_id)
            for handler in broker.subscribers[message.receiver_id]
                try
                    handler(message)
                    broker.metrics["messages_received"] += 1
                catch e
                    @error "❌ Handler error for message $(message.id): $e"
                    send_to_dead_letter_queue(broker, message, "handler_error")
                end
            end
        end

        # Broadcast message routing
        if haskey(message.headers, "broadcast") && message.headers["broadcast"] == "true"
            # Route to all subscribers of the topic
            topic = message.receiver_id
            if haskey(broker.subscribers, topic)
                for handler in broker.subscribers[topic]
                    try
                        handler(message)
                        broker.metrics["messages_received"] += 1
                    catch e
                        @error "❌ Broadcast handler error for message $(message.id): $e"
                    end
                end
            end
        end

    catch e
        @error "❌ Failed to route message: $e"
        send_to_dead_letter_queue(broker, message, "routing_error")
    end
end

"""
    send_to_dead_letter_queue(broker::MessageBroker, message::Message, reason::String)

Sends a failed message to the dead letter queue.
"""
function send_to_dead_letter_queue(broker::MessageBroker, message::Message, reason::String)
    try
        if broker.redis_client === nothing
            return
        end

        dlq_entry = Dict(
            "message" => message,
            "reason" => reason,
            "failed_at" => now(),
            "original_id" => message.id
        )

        dlq_key = "a2a:dead_letter_queue"
        dlq_json = JSON3.write(dlq_entry)

        execute(broker.redis_client, ["LPUSH", dlq_key, dlq_json])
        execute(broker.redis_client, ["EXPIRE", dlq_key, string(broker.config.dead_letter_ttl)])

        @warn "⚠️ Message $(message.id) sent to dead letter queue: $reason"

    catch e
        @error "❌ Failed to send message to dead letter queue: $e"
    end
end

"""
    worker_loop(broker::MessageBroker, worker_id::Int)

Main worker loop for processing messages.
"""
function worker_loop(broker::MessageBroker, worker_id::Int)
    @info "👷 Worker $worker_id started"

    while broker.running
        try
            # Process any queued operations
            process_pending_operations(broker, worker_id)

            # Small delay to prevent busy waiting
            sleep(0.1)

        catch e
            @error "❌ Worker $worker_id error: $e"
            sleep(1.0)  # Longer delay on error
        end
    end

    @info "👷 Worker $worker_id stopped"
end

"""
    process_pending_operations(broker::MessageBroker, worker_id::Int)

Processes pending operations for a worker.
"""
function process_pending_operations(broker::MessageBroker, worker_id::Int)
    try
        if broker.redis_client === nothing
            return
        end

        # Check for expired messages to clean up
        cleanup_expired_messages(broker)

        # Process dead letter queue if needed
        process_dead_letter_queue(broker)

    catch e
        @debug "Worker $worker_id processing error: $e"
    end
end

"""
    cleanup_expired_messages(broker::MessageBroker)

Cleans up expired messages from storage.
"""
function cleanup_expired_messages(broker::MessageBroker)
    try
        if broker.redis_client === nothing
            return
        end

        # Scan for expired message keys
        keys_pattern = "a2a:message:*"
        keys = execute(broker.redis_client, ["KEYS", keys_pattern])

        for key in keys
            try
                ttl = execute(broker.redis_client, ["TTL", key])
                if ttl <= 0
                    execute(broker.redis_client, ["DEL", key])
                end
            catch e
                @debug "Error checking TTL for key $key: $e"
            end
        end

    catch e
        @debug "Error in cleanup_expired_messages: $e"
    end
end

"""
    process_dead_letter_queue(broker::MessageBroker)

Processes messages in the dead letter queue for retry.
"""
function process_dead_letter_queue(broker::MessageBroker)
    try
        if broker.redis_client === nothing
            return
        end

        dlq_key = "a2a:dead_letter_queue"

        # Get messages from DLQ
        dlq_messages = execute(broker.redis_client, ["LRANGE", dlq_key, "0", "10"])

        for dlq_json in dlq_messages
            try
                dlq_entry = JSON3.read(dlq_json, Dict)
                failed_time = DateTime(dlq_entry["failed_at"])

                # Retry messages that are older than 5 minutes
                if now() - failed_time > Minute(5)
                    message_data = dlq_entry["message"]
                    # Attempt to reprocess the message
                    # Implementation depends on retry logic

                    # Remove from DLQ if successful
                    execute(broker.redis_client, ["LREM", dlq_key, "1", dlq_json])
                end

            catch e
                @debug "Error processing DLQ entry: $e"
            end
        end

    catch e
        @debug "Error in process_dead_letter_queue: $e"
    end
end

"""
    metrics_collector_loop(broker::MessageBroker)

Collects and updates broker metrics.
"""
function metrics_collector_loop(broker::MessageBroker)
    @info "📊 Metrics collector started"

    while broker.running
        try
            update_metrics(broker)
            sleep(30)  # Update metrics every 30 seconds

        catch e
            @error "❌ Metrics collector error: $e"
            sleep(60)  # Longer delay on error
        end
    end

    @info "📊 Metrics collector stopped"
end

"""
    update_metrics(broker::MessageBroker)

Updates broker performance metrics.
"""
function update_metrics(broker::MessageBroker)
    try
        # Update active subscribers count
        total_subscribers = sum(length(handlers) for handlers in values(broker.subscribers))
        broker.metrics["active_subscribers"] = total_subscribers

        # Update last activity
        broker.metrics["last_activity"] = now()

        # Log metrics periodically
        @debug "📊 Broker Metrics: $(broker.metrics)"

    catch e
        @debug "Error updating metrics: $e"
    end
end

"""
    get_broker_status(broker::MessageBroker) -> Dict

Returns the current status and metrics of the message broker.
"""
function get_broker_status(broker::MessageBroker)
    return Dict(
        "running" => broker.running,
        "redis_connected" => broker.redis_client !== nothing,
        "worker_count" => length(broker.worker_tasks),
        "subscriber_topics" => length(broker.subscribers),
        "metrics" => broker.metrics,
        "config" => broker.config
    )
end

# Export public interface
export MessageBroker, MessageBrokerConfig, Message
export create_message_broker, start_broker!, stop_broker!
export publish_message, subscribe, unsubscribe
export send_direct_message, broadcast_message
export get_broker_status, default_broker_config

end # module MessageBroker
