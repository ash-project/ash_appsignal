# SPDX-FileCopyrightText: 2023 ash_appsignal contributors <https://github.com/ash-project/ash_appsignal/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAppsignal do
  @moduledoc """
  Documentation for `AshAppsignal`.
  """

  use Ash.Tracer
  require Appsignal.Utils
  @monitor Appsignal.Utils.compile_env(:appsignal, :appsignal_monitor, Appsignal.Monitor)
  @table :"$appsignal_registry"

  @impl Ash.Tracer
  def start_span(type, name) do
    appsignal_parent = current_appsignal_span()

    appsignal_span = Appsignal.Tracer.create_span("ash", appsignal_parent)

    appsignal_span
    |> Appsignal.Span.set_name(name)
    |> Appsignal.Span.set_attribute("appsignal:category", "#{type}.ash")

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
    allowed_types = Application.get_env(:ash_appsignal, :trace_types) || [:custom, :action]

    is_nil(allowed_types) || Enum.member?(allowed_types, type)
  end

  @impl Ash.Tracer
  def stop_span do
    Appsignal.Tracer.current_span()
    |> Appsignal.Tracer.close_span()

    :ok
  end

  @impl Ash.Tracer
  def get_span_context do
    %{
      appsignal_span: Appsignal.Tracer.current_span() || Process.get(:parent_appsignal_span)
    }
  end

  @impl Ash.Tracer
  def set_span_context(%{appsignal_span: appsignal_span}) do
    if appsignal_span do
      register(%{appsignal_span | pid: self()})
      Process.put(:parent_appsignal_span, appsignal_span)
    end

    :ok
  end

  @impl Ash.Tracer
  def set_metadata(_type, _metadata) do
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
      {reported_error, stacktrace} = reported_error_and_stacktrace(error, opts[:stacktrace])

      Appsignal.Span.add_error(current_appsignal_span(), reported_error, stacktrace)
    after
      if needs_span? do
        stop_span()
      end
    end

    :ok
  end

  @doc false
  # The stacktrace reported to Appsignal is, in order of preference: the
  # stacktrace the error was originally created with, the stacktrace provided
  # by the caller (e.g. `__STACKTRACE__` from Ash's tracer), and only as a
  # last resort the stacktrace on the normalized error, which may have been
  # captured at normalization time and point here rather than the raise site.
  def reported_error_and_stacktrace(error, stacktrace) do
    reported_error = normalize_error(error, stacktrace)

    stacktrace =
      error_stacktrace(error) || stacktrace || error_stacktrace(reported_error)

    {reported_error, stacktrace}
  end

  defp normalize_error(nil, _stacktrace) do
    nil
  end

  defp normalize_error(error, stacktrace) do
    case Ash.Error.to_error_class(error, stacktrace: stacktrace) do
      %Ash.Error.Unknown{} = unknown -> unknown
      %{errors: [single]} -> single
      other -> other
    end
  rescue
    _coercion_error ->
      error
  end

  defp error_stacktrace(%{stacktrace: %{stacktrace: [_ | _] = stacktrace}}), do: stacktrace
  defp error_stacktrace(_other), do: nil

  defp current_appsignal_span do
    Appsignal.Tracer.current_span() || Process.get(:parent_appsignal_span)
  end

  defp register(%Appsignal.Span{pid: pid} = span) do
    if insert({pid, span}) do
      @monitor.add()
      span
    end
  end

  defp insert(span) do
    :ets.insert(@table, span)
  rescue
    ArgumentError -> nil
  end
end
