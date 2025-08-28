defmodule AshHoneybadger do
  @moduledoc """
  Honeybadger error tracking and events integration for Ash Framework.
  
  This module implements the `Ash.Tracer` behaviour to capture Ash operations
  and send them as events to Honeybadger Insights for monitoring and analysis.
  
  ## Configuration
  
  Enable Honeybadger Insights in your config:
  
      config :honeybadger,
        insights_enabled: true,
        api_key: "your-api-key"
  
  Add the tracer to your Ash resources:
  
      use Ash.Resource,
        domain: YourDomain,
        tracers: [AshHoneybadger]
  
  ## Event Structure
  
  Events are emitted for span lifecycle with correlation IDs to group
  related operations within a request context.
  """

  use Ash.Tracer
  alias AshHoneybadger.CorrelationId

  # Lightweight span-like structure for maintaining Tracer interface compliance
  defstruct [
    :id,
    :name, 
    :type,
    :start_time,
    :correlation_id,
    :parent_id,
    :metadata
  ]

  @impl Ash.Tracer
  def start_span(type, name) do
    parent_span = get_current_span()
    correlation_id = CorrelationId.get_correlation_id()
    
    span = %__MODULE__{
      id: generate_span_id(),
      name: name,
      type: type,
      start_time: System.monotonic_time(:microsecond),
      correlation_id: correlation_id,
      parent_id: parent_span && parent_span.id,
      metadata: %{}
    }
    
    # Store span for context management
    set_current_span(span)
    
    # Emit start event to Honeybadger
    if should_emit_event?(type, :start) do
      Honeybadger.event("#{type}.ash.start", %{
        span_id: span.id,
        name: name,
        correlation_id: correlation_id,
        parent_id: span.parent_id,
        timestamp: System.system_time(:microsecond)
      })
    end

    :ok
  end

  @impl Ash.Tracer
  def trace_type?(:custom) do
    true
  end

  def trace_type?({:custom, type}) do
    trace_type?(type)
  end

  def trace_type?(type) do
    allowed_types = Application.get_env(:ash_honeybadger, :trace_types) || [:custom, :action]

    is_nil(allowed_types) || Enum.member?(allowed_types, type)
  end

  @impl Ash.Tracer
  def stop_span do
    case get_current_span() do
      %__MODULE__{} = span ->
        duration_microseconds = System.monotonic_time(:microsecond) - span.start_time
        
        # Emit completion event
        if should_emit_event?(span.type, :complete) do
          Honeybadger.event("#{span.type}.ash.complete", %{
            span_id: span.id,
            name: span.name,
            correlation_id: span.correlation_id,
            parent_id: span.parent_id,
            duration_microseconds: duration_microseconds,
            timestamp: System.system_time(:microsecond),
            metadata: span.metadata
          })
        end
        
        # Restore parent span context
        clear_current_span()
        
      nil ->
        :ok
    end
  end

  @impl Ash.Tracer
  def get_span_context do
    %{
      honeybadger_span: get_current_span(),
      correlation_id: CorrelationId.get_correlation_id()
    }
  end

  @impl Ash.Tracer
  def set_span_context(%{honeybadger_span: span, correlation_id: correlation_id}) do
    if span do
      set_current_span(span)
    end
    
    if correlation_id do
      CorrelationId.set_correlation_id(correlation_id)
    end
  end
  
  # Handle legacy AppSignal context for backwards compatibility
  def set_span_context(%{appsignal_span: _}) do
    :ok
  end
  
  # Handle empty context
  def set_span_context(%{}) do
    :ok
  end

  @impl Ash.Tracer
  def set_metadata(_type, metadata) do
    case get_current_span() do
      %__MODULE__{} = span ->
        updated_span = %{span | metadata: Map.merge(span.metadata, metadata || %{})}
        set_current_span(updated_span)
      _ ->
        :ok
    end
  end

  @impl Ash.Tracer
  def set_error(error, opts \\ []) do
    current_span = get_current_span()
    correlation_id = CorrelationId.get_correlation_id()
    
    # Create temporary span if none exists
    needs_span? = is_nil(current_span)
    if needs_span? do
      start_span(:custom, "Error")
    end

    # Send error to Honeybadger with context
    error_context = %{
      correlation_id: correlation_id,
      span_id: current_span && current_span.id,
      span_name: current_span && current_span.name,
      timestamp: System.system_time(:microsecond)
    }
    
    # Use Honeybadger.notify for error reporting
    Honeybadger.notify(error, 
      stacktrace: opts[:stacktrace],
      context: error_context,
      fingerprint: correlation_id
    )
    
    # Also emit error event for insights
    Honeybadger.event("error.ash", %{
      error_class: error.__struct__ |> to_string(),
      error_message: Exception.message(error),
      correlation_id: correlation_id,
      span_id: current_span && current_span.id,
      timestamp: System.system_time(:microsecond)
    })

    if needs_span? do
      stop_span()
    end

    :ok
  end

  # Private helper functions
  
  defp get_current_span do
    Process.get(:ash_honeybadger_span)
  end
  
  defp set_current_span(span) do
    Process.put(:ash_honeybadger_span, span)
  end
  
  defp clear_current_span do
    Process.delete(:ash_honeybadger_span)
  end
  
  defp generate_span_id do
    System.unique_integer([:positive, :monotonic]) |> to_string()
  end
  
  # Event emission filtering to control volume
  defp should_emit_event?(type, phase) do
    case Application.get_env(:ash_honeybadger, :event_filter, :all) do
      :none -> false
      :errors_only -> type == :custom and phase == :start
      :actions_only -> type == :action
      :all -> true
      filter_fn when is_function(filter_fn, 2) -> filter_fn.(type, phase)
    end
  end
end
