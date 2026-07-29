# SPDX-FileCopyrightText: 2023 ash_appsignal contributors <https://github.com/ash-project/ash_appsignal/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshAppsignalTest do
  use ExUnit.Case

  @stacktrace [
    {MyApp.Storage.Workspaces, :delete_by_id, 1, [file: ~c"lib/my_app/workspaces.ex", line: 129]},
    {MyApp.Changes.Deprovision, :change, 3, [file: ~c"lib/my_app/deprovision.ex", line: 19]}
  ]

  describe "reported_error_and_stacktrace/2" do
    test "uses the caller-provided stacktrace when a plain exception is normalized" do
      error = %RuntimeError{message: "something went wrong"}

      {reported_error, stacktrace} =
        AshAppsignal.reported_error_and_stacktrace(error, @stacktrace)

      assert %Ash.Error.Unknown{} = reported_error
      assert stacktrace == @stacktrace
    end

    test "does not report the stacktrace captured during normalization" do
      error = %RuntimeError{message: "something went wrong"}

      {_reported_error, stacktrace} =
        AshAppsignal.reported_error_and_stacktrace(error, @stacktrace)

      refute Enum.any?(stacktrace, fn {module, _fun, _arity, _location} ->
               module in [AshAppsignal, Ash.Error]
             end)
    end

    test "prefers the stacktrace the error was originally created with" do
      error = Ash.Error.to_ash_error(%RuntimeError{message: "boom"}, @stacktrace)

      other_stacktrace = [{Foo, :bar, 0, [file: ~c"lib/foo.ex", line: 1]}]

      {_reported_error, stacktrace} =
        AshAppsignal.reported_error_and_stacktrace(error, other_stacktrace)

      assert stacktrace == @stacktrace
    end

    test "falls back to the normalized error's stacktrace when nothing else is available" do
      {_reported_error, stacktrace} =
        AshAppsignal.reported_error_and_stacktrace(%RuntimeError{message: "boom"}, nil)

      assert is_list(stacktrace)
    end

    test "handles nil errors" do
      assert {nil, @stacktrace} = AshAppsignal.reported_error_and_stacktrace(nil, @stacktrace)
    end
  end
end
