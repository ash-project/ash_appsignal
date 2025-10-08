# SPDX-FileCopyrightText: 2020 Zach Daniel
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
