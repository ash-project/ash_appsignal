<!--
SPDX-FileCopyrightText: 2023 ash_appsignal contributors <https://github.com/ash-project/ash_appsignal/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Getting Started with AshAppsignal

## Installation

Add `ash_appsignal` to your list of dependencies in `mix.exs`:


```elixir
def deps do
  [
    {:ash_appsignal, "~> 0.1.2"}
  ]
end
```

## Configuration

After installing the `ash_appsignal` dependency, add this to your config:

```elixir
# `config` supports a list, so this can be combined with other tracers
config :ash, :tracer, [AshAppsignal]

# Optionally configure span types to be sent to appsignal. The default is
# [:custom, :action, :flow]
# We suggest using this list. It trims down some noisy traces that Ash emits
config :ash_appsignal,
  trace_types: [
    :custom,
    :action
  ]
```

For all available types, see the documentation for `Ash.Tracer`.

Thats it! Additional traces and spans from Ash will now be displayed in AppSignal.
