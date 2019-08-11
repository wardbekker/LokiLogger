defmodule LokiLoggerTest do
  use ExUnit.Case
  doctest LokiLogger

  test "greets the world" do
    require Logger
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
end
