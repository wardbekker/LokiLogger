use Mix.Config

config :logger,
  backends: [LokiLogger]

config :logger, :loki_logger,
  level: :debug,
  format: "$metadata level=$level $levelpad$message",
  metadata: :all,
  max_buffer: 300,
  loki_labels: %{application: "loki_logger_library", elixir_node: node()},
  loki_host: "http://localhost:3100",
  loki_scope_org_id: "acme_inc"

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
