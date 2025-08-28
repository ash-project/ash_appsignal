# Getting Started with AshHoneybadger

## Installation

Add `ash_honeybadger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_honeybadger, "~> 0.1.3"},
    {:honeybadger, "~> 0.15"}
  ]
end
```

## Configuration

### Honeybadger Setup

First, configure Honeybadger itself:

```elixir
config :honeybadger,
  api_key: "your-honeybadger-api-key",
  insights_enabled: true
```

### AshHoneybadger Setup

Add the tracer to your Ash configuration:

```elixir
# `config` supports a list, so this can be combined with other tracers
config :ash, :tracer, [AshHoneybadger]

# Optionally configure span types to be tracked. The default is
# [:custom, :action]
config :ash_honeybadger,
  trace_types: [
    :custom,
    :action
  ]

# Control event volume to prevent API rate limits
config :ash_honeybadger,
  event_filter: :actions_only  # :all, :none, :errors_only, :actions_only
```

## What You Get

- **Error Tracking**: Automatic error reporting with correlation IDs linking errors to specific requests
- **Event Insights**: Track Ash operations with timing data in Honeybadger Insights
- **Request Correlation**: Events are automatically grouped by request ID from Phoenix/Plug contexts
- **Configurable Volume**: Filter events to control API usage and focus on what matters

For all available configuration options, see the documentation for `AshHoneybadger`.
