defmodule AshAppsignal do
  @moduledoc """
  Documentation for `AshAppsignal`.
  """

  use Ash.Tracer

  @impl Ash.Tracer
  def start_span(type, name) do
    appsignal_parent = current_appsignal_span()

    appsignal_span = Appsignal.Tracer.create_span("ash", appsignal_parent)

    appsignal_span
    |> Appsignal.Span.set_name(name)
    |> Appsignal.Span.set_attribute("appsignal:category", to_string(type))

    :ok
  end

  @impl Ash.Tracer
  def trace_type?(:custom) do
    true
  end

  def trace_type?(type) do
    allowed_types = Application.get_env(:ash_appsignal, :trace_types)

    is_nil(allowed_types) || Enum.member?(allowed_types, type)
  end

  @impl Ash.Tracer
  def stop_span do
    Appsignal.Tracer.current_span()
    |> Appsignal.Tracer.close_span()
  end

  @impl Ash.Tracer
  def get_span_context do
    %{
      appsignal_span: Appsignal.Tracer.current_span() || Process.get(:parent_appsignal_span)
    }
  end

  @impl Ash.Tracer
  def set_span_context(%{appsignal_span: appsignal_span}) do
    Process.put(:parent_appsignal_span, appsignal_span)
  end

  @impl Ash.Tracer
  def set_metadata(_type, metadata) do
    current_appsignal_span = current_appsignal_span()

    if current_appsignal_span do
      # This doesn't appear to show up anywhere in appsignal
      # I'm not sure how to actually get arbitrary metadata at the span level working
      # or if it is possible
      Appsignal.Span.set_sample_data(
        current_appsignal_span,
        "params",
        Map.new(metadata, fn {key, value} ->
          {key, string_metadata(value)}
        end)
      )
    end

    :ok
  end

  @impl Ash.Tracer
  def set_error(error, opts \\ []) do
    current_span = current_appsignal_span()
    needs_span? = is_nil(current_span)

    if needs_span? do
      start_span(:custom, "Error")
    end

    try do
      Appsignal.Span.add_error(current_appsignal_span(), error, opts[:stacktrace])
    after
      if needs_span? do
        stop_span()
      end
    end

    :ok
  end

  defp current_appsignal_span do
    Appsignal.Tracer.current_span() || Process.get(:parent_appsignal_span)
  end

  def string_metadata(%resource{} = value) do
    if Ash.Resource.Info.resource?(resource) do
      format_record(value)
    else
      inspect(value)
    end
  end

  def string_metadata(other) do
    value =
      if is_atom(other) do
        other
        |> to_string()
        |> String.trim_leading("Elixir.")
      else
        other
      end

    try do
      to_string(value)
    rescue
      _ -> ""
    end
  end

  defp format_record(%resource{} = record) do
    case Ash.Resource.Info.primary_key(resource) do
      [field] ->
        value =
          case Map.get(record, field) do
            value when is_binary(value) ->
              value

            value ->
              inspect(value)
          end

        "#{Ash.Resource.Info.short_name(resource)}-#{value}"

      fields ->
        field_values =
          Enum.map_join(fields, ",", fn field ->
            value =
              case Map.get(record, field) do
                value when is_binary(value) ->
                  value

                value ->
                  inspect(value)
              end

            "#{field}:#{value}"
          end)

        "#{Ash.Resource.Info.short_name(resource)}-#{field_values}"
    end
  end
end
