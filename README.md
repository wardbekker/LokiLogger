# LokiLogger

LokiLogger is an Elixir logger backend providing support for Logging to [Grafana Loki](https://github.com/grafana/loki)

[![Hex.pm Version](http://img.shields.io/hexpm/v/loki_logger.svg?style=flat)](https://hex.pm/packages/loki_logger)

## Known issues

* "works-on-my-machine" level of quality. Love to get your feedback in the repo's Github issues

## Features (and TODO)

* [x] Elixir Logger formatting
* [x] Elixir Logger metadata
    * [x] Loki Scope-Org-Id header for multi-tenancy
* [x] Timezone aware
* [X] Snappy compressed proto format in the HTTP Body  
* [ ] Async http call to backend.
* [ ] Proper unit tests.
* [ ] HTTP post retry strategy on temporary loki backend failure or network hiccups.
* [ ] Authentication with basic auth and/or Oauth2 reverse proxy.
* [ ] CI build integration (e.g. TravisCI) 

## Installation

The package can be installed by adding `loki_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:loki_logger, "~> 0.3.0"}
  ]
end
```

## Configuration

### Elixir Project

Loki Logger's behavior is controlled using the application configuration environment:

* __loki_host__ : the hostname of the syslog server e.g. http://localhost:3100
* __loki_labels__ : the Loki log labels used to select the log stream in e.g. Grafana 
* __loki_scope_org_id__: optional tenant ID for multitenancy. Currently not (yet?) supported in Grafana when enforced with `auth_enabled: true` in Loki config 
* __level__: logging threshold. Messages "above" this threshold will be discarded. The supported levels, ordered by precedence are :debug, :info, :warn, :error.
* __format__: the format message used to print logs. Defaults to: "$metadata level=$level $levelpad$message". It may also be a {module, function} tuple that is invoked with the log level, the message, the current timestamp and the metadata.
* __metadata__: the metadata to be printed by $metadata. Defaults to to :all, which prints all metadata.
* __max_buffer__: the amount of entries to buffer before posting to the Loki REST api. Defaults to 32.  

For example, the following `config/config.exs` file sets up Loki Logger using
level debug, with `application` label `loki_logger_library`. 

```elixir
use Mix.Config

config :logger,
       backends: [LokiLogger]

config :logger, :loki_logger,
       level: :debug,
       format: "$metadata level=$level $levelpad$message",
       metadata: :all,
       max_buffer: 300,
       loki_labels: %{application: "loki_logger_library", elixir_node: node()},
       loki_host: "http://localhost:3100"
```

# Protobuff lib regeneration

only needed for development 

```shell script
protoc --proto_path=./lib/proto --elixir_out=./lib lib/proto/loki.proto 
```

## License

Loki Logger is copyright (c) 2019 Ward Bekker 

The source code is released under the Apache v2.0 License.

Check [LICENSE](LICENSE) for more information.

