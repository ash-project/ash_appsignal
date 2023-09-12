# Trace with Appsignal

After installing the `ash_appsignal` dependency, add this to your config:

```elixir
# config supports a list, so this can be combined with other tracers
config :ash, :tracer, [AshAppsignal]

# we suggest using this list. It trims down some noisy traces that Ash emits
config :ash_appsignal,
  trace_types: [
    :custom,
    :action,
    :changeset,
    :validation,
    :change,
    :before_transaction,
    :before_action,
    :after_transaction,
    :after_action,
    :custom_flow_step,
    :flow,
    :query,
    :preparation
  ]
```
