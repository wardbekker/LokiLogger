defmodule LokiLogger do
  @behaviour :gen_event
  @moduledoc false

  defstruct buffer: [],
            buffer_size: 0,
            format: nil,
            level: nil,
            max_buffer: nil,
            metadata: nil,
            loki_labels: nil,
            loki_host: nil,
            loki_scope_org_id: nil

  def init(LokiLogger) do
    config = Application.get_env(:logger, :loki_logger)
    {:ok, init(config, %__MODULE__{})}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = configure_merge(Application.get_env(:logger, :loki_logger), opts)
    {:ok, init(config, %__MODULE__{})}
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, state) do
    %{level: log_level, buffer_size: buffer_size, max_buffer: max_buffer} = state

    cond do
      not meet_level?(level, log_level) ->
        {:ok, state}

      buffer_size < max_buffer ->
        {:ok, buffer_event(level, msg, ts, md, state)}

      buffer_size === max_buffer ->
        state = buffer_event(level, msg, ts, md, state)
        {:ok, flush(state)}
    end
  end

  def handle_event(:flush, state) do
    {:ok, flush(state)}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end


  ## Helpers

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp configure(options, state) do
    config = configure_merge(Application.get_env(:logger, :loki_logger), options)
    Application.put_env(:logger, :loki_logger, config)
    init(config, state)
  end

  defp init(config, state) do
    level = Keyword.get(config, :level, :info)
    format = Logger.Formatter.compile(Keyword.get(config, :format, "$metadata level=$level $levelpad$message"))
    metadata = Keyword.get(config, :metadata, :all)
               |> configure_metadata()
    max_buffer = Keyword.get(config, :max_buffer, 32)
    loki_labels = Keyword.get(config, :loki_labels, %{application: "loki_logger_library"})
    loki_host = Keyword.get(config, :loki_host, "http://localhost:3100")
    loki_scope_org_id = Keyword.get(config, :loki_scope_org_id, "fake")

    %{
      state
    |
      format: format,
      metadata: metadata,
      level: level,
      max_buffer: max_buffer,
      loki_labels: loki_labels,
      loki_host: loki_host,
      loki_scope_org_id: loki_scope_org_id
    }
  end

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp configure_merge(env, options) do
    Keyword.merge(
      env,
      options,
      fn
        _, _v1, v2 -> v2
      end
    )
  end

  defp buffer_event(level, msg, ts, md, state) do
    %{buffer: buffer, buffer_size: buffer_size} = state
    epoch_nano = DateTime.to_unix(Timex.to_datetime(ts, Timex.Timezone.Local.lookup()), :nanosecond)
    buffer = buffer ++ [{epoch_nano, format_event(level, msg, ts, md, state)}]
    %{state | buffer: buffer, buffer_size: buffer_size + 1}
  end

  defp async_io(loki_host, loki_labels, loki_scope_org_id, output)  do
    bin_push_request = generate_bin_push_request(loki_labels, output)

    http_headers = [{"Content-Type", "application/x-protobuf"}, {"X-Scope-OrgID", loki_scope_org_id}]

    # TODO: replace with async http call
    case HTTPoison.post "#{loki_host}/api/prom/push", bin_push_request,
                        http_headers do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        #expected
        :noop
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.puts inspect(
                  output
                  |> List.keysort(1)
                  |> Enum.reverse,
                  pretty: true
                )

        raise "unexpected status code from loki backend #{status_code}" <> Exception.format_exit(body)
      {:error, %HTTPoison.Error{reason: reason}} ->
        raise "http error from loki backend " <> Exception.format_exit(reason)
    end
  end

  defp generate_bin_push_request(loki_labels, output) do
    labels = Enum.map(loki_labels, fn {k, v} -> "#{k}=\"#{v}\"" end)
             |> Enum.join(",")
    labels = "{" <> labels <> "}"
    # sort entries on epoch seconds as first element of tuple, to prevent out-of-order entries
    sorted_entries = output
                     |> List.keysort(0)
                     |> Enum.map(
                          fn {ts, line} ->
                            seconds = Kernel.trunc(ts / 1_000_000_000)
                            nanos = ts - (seconds * 1_000_000_000)
                            Logproto.Entry.new(
                              timestamp: Google.Protobuf.Timestamp.new(seconds: seconds, nanos: nanos),
                              line: line
                            )
                          end
                        )

    request = Logproto.PushRequest.new(
      streams: [
        Logproto.Stream.new(
          labels: labels,
          entries: sorted_entries
        )
      ]
    )

    {:ok, bin_push_request} = Logproto.PushRequest.encode(request)
                              |> :snappyer.compress

    bin_push_request
  end

  defp format_event(level, msg, ts, md, %{format: format, metadata: keys}  = _state) do
    List.to_string(Logger.Formatter.format(format, level, msg, ts, take_metadata(md, keys)))
  end

  defp take_metadata(metadata, :all) do
    Keyword.drop(metadata, [:crash_reason, :ancestors, :callers])
  end

  defp take_metadata(metadata, keys) do
    Enum.reduce(
      keys,
      [],
      fn key, acc ->
        case Keyword.fetch(metadata, key) do
          {:ok, val} -> [{key, val} | acc]
          :error -> acc
        end
      end
    )
  end

  defp log_buffer(%{buffer_size: 0, buffer: []} = state), do: state

  defp log_buffer(
         %{loki_host: loki_host, loki_labels: loki_labels, loki_scope_org_id: loki_scope_org_id, buffer: buffer} = state
       ) do
    async_io(loki_host, loki_labels, loki_scope_org_id, buffer)
    %{state | buffer: [], buffer_size: 0}
  end

  defp flush(state) do
    log_buffer(state)
  end
end




