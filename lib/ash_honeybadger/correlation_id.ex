defmodule AshHoneybadger.CorrelationId do
  @moduledoc """
  Handles correlation ID extraction and generation for request tracing.
  
  Correlation IDs are used to group related events in Honeybadger Insights.
  This module attempts to extract correlation IDs from various sources in
  priority order, falling back to generation when none are available.
  """

  @doc """
  Gets or generates a correlation ID for the current process.
  
  Tries the following sources in order:
  1. Phoenix/Plug request ID from Logger metadata
  2. Custom correlation header from Plug.Conn
  3. GraphQL context (Absinthe)
  4. Process dictionary cache
  5. Generate and cache a new UUID
  """
  def get_correlation_id do
    phoenix_request_id() ||
    plug_correlation_id() ||
    graphql_context_id() ||
    process_correlation_id() ||
    generate_and_store_correlation_id()
  end

  @doc """
  Explicitly sets a correlation ID for the current process.
  """
  def set_correlation_id(id) when is_binary(id) do
    Process.put(:ash_correlation_id, id)
    id
  end

  @doc """
  Clears the correlation ID from the current process.
  """
  def clear_correlation_id do
    Process.delete(:ash_correlation_id)
  end

  # Try Phoenix Logger metadata first - most common source
  defp phoenix_request_id do
    case Logger.metadata()[:request_id] do
      nil -> nil
      id when is_binary(id) -> id
      id -> inspect(id)
    end
  end

  # Check for custom correlation header if we have access to Plug.Conn
  defp plug_correlation_id do
    case Process.get(:plug_conn) do
      %Plug.Conn{} = conn ->
        Plug.Conn.get_req_header(conn, "x-correlation-id") |> List.first() ||
        Plug.Conn.get_req_header(conn, "x-request-id") |> List.first()
      _ -> nil
    end
  end

  # Check Absinthe GraphQL context
  defp graphql_context_id do
    case Process.get(:absinthe_context) do
      %{request_id: id} when is_binary(id) -> id
      %{correlation_id: id} when is_binary(id) -> id
      _ -> nil
    end
  end

  # Check if already cached in process dictionary
  defp process_correlation_id do
    Process.get(:ash_correlation_id)
  end

  # Generate new correlation ID and cache it
  defp generate_and_store_correlation_id do
    id = generate_uuid()
    Process.put(:ash_correlation_id, id)
    id
  end

  # Simple UUID generation - using system time + unique integer for uniqueness
  defp generate_uuid do
    timestamp = System.system_time(:microsecond)
    unique_part = System.unique_integer([:positive, :monotonic])
    "ash-#{timestamp}-#{unique_part}"
  end
end