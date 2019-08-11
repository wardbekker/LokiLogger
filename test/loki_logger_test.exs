defmodule LokiLoggerTest do
  use ExUnit.Case
  doctest LokiLogger
  require Logger

  test "greets the world" do
    Logger.info("Sample message")
    Logger.debug("Sample message")
    Logger.error("Sample message")
    Logger.info("Sample message")
    Logger.debug("Sample message")
    Logger.error("Sample message")
    Logger.info("Sample message")
    Logger.debug("Sample message")
    Logger.error("Sample message")
  end

  test "benchmark" do
    Benchee.run(
      %{
        "debug" => fn -> Logger.debug("Sample message") end,
      },
      time: 10,
      memory_time: 2,
      parallel: 1
    )
  end
end
