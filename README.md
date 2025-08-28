![Logo](https://github.com/ash-project/ash/blob/main/logos/cropped-for-header-black-text.png?raw=true#gh-light-mode-only)
![Logo](https://github.com/ash-project/ash/blob/main/logos/cropped-for-header-white-text.png?raw=true#gh-dark-mode-only)

[![CI](https://github.com/ash-project/ash_honeybadger/actions/workflows/elixir.yml/badge.svg)](https://github.com/ash-project/ash_honeybadger/actions/workflows/elixir.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Hex version badge](https://img.shields.io/hexpm/v/ash_honeybadger.svg)](https://hex.pm/packages/ash_honeybadger)
[![Hexdocs badge](https://img.shields.io/badge/docs-hexdocs-purple)](https://hexdocs.pm/ash_honeybadger)

# AshHoneybadger

Welcome! `AshHoneybadger` is an integration between [Ash Framework](https://hexdocs.pm/ash) and [Honeybadger](https://www.honeybadger.io) for error tracking and event insights.

## Features

- **Error Tracking**: Automatic error reporting with correlation IDs for request tracing
- **Event Insights**: Track Ash operations and performance with Honeybadger Insights  
- **Correlation IDs**: Automatic extraction from Phoenix, Plug, GraphQL contexts
- **Configurable Filtering**: Control event volume with flexible filtering options

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

Configure Honeybadger in your `config.exs`:

```elixir
config :honeybadger,
  api_key: "your-honeybadger-api-key",
  insights_enabled: true
```

Add the tracer to your Ash resources:

```elixir
use Ash.Resource,
  domain: YourDomain,
  tracers: [AshHoneybadger]
```

## Event Filtering

Control event volume with filtering options:

```elixir
config :ash_honeybadger,
  event_filter: :actions_only  # :all, :none, :errors_only, :actions_only
```

## Tutorials

- [Get Started with AshHoneybadger](documentation/tutorials/getting-started-with-ash-honeybadger.md)
