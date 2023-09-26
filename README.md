# AshAppsignal

A drop in Ash.Tracer implementation for Appsignal. Follow the appsignal setup
before setting this up.

## Setup

Add the dependency to your application

```elixir
def deps do
  [
    {:ash_appsignal, "~> 0.1.1"}
  ]
end
```

Add this to your config:

```elixir
# config supports a list, so this can be combined with other tracers
config :ash, :tracer, [AshAppsignal]

# we suggest using this list. It trims down some noisy traces that Ash emits
config :ash_appsignal,
  trace_types: [
    :custom,
    :action,
    :custom_flow_step,
    :flow,
    :query,
    :preparation
  ]
```

Thats it! Additional traces & spans from Ash will be displayed in appsignal.
