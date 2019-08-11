use Mix.Config

config :logger,
       backends: [LokiLogger]

config :logger, :loki_logger,
       level: :debug,
       format: "$metadata level=$level $levelpad$message",
       metadata: :all,
       max_buffer: 300,
       loki_labels: %{application: "loki_logger_library"},
       loki_host: "http://localhost:3100"