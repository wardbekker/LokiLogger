defmodule Logproto.PushRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          streams: [Logproto.Stream.t()]
        }
  defstruct [:streams]

  field(:streams, 1, repeated: true, type: Logproto.Stream)
end

defmodule Logproto.PushResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Logproto.QueryRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          query: String.t(),
          limit: non_neg_integer,
          start: Google.Protobuf.Timestamp.t() | nil,
          end: Google.Protobuf.Timestamp.t() | nil,
          direction: atom | integer,
          regex: String.t()
        }
  defstruct [:query, :limit, :start, :end, :direction, :regex]

  field(:query, 1, type: :string)
  field(:limit, 2, type: :uint32)
  field(:start, 3, type: Google.Protobuf.Timestamp)
  field(:end, 4, type: Google.Protobuf.Timestamp)
  field(:direction, 5, type: Logproto.Direction, enum: true)
  field(:regex, 6, type: :string)
end

defmodule Logproto.QueryResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          streams: [Logproto.Stream.t()]
        }
  defstruct [:streams]

  field(:streams, 1, repeated: true, type: Logproto.Stream)
end

defmodule Logproto.LabelRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          values: boolean,
          start: Google.Protobuf.Timestamp.t() | nil,
          end: Google.Protobuf.Timestamp.t() | nil
        }
  defstruct [:name, :values, :start, :end]

  field(:name, 1, type: :string)
  field(:values, 2, type: :bool)
  field(:start, 3, type: Google.Protobuf.Timestamp)
  field(:end, 4, type: Google.Protobuf.Timestamp)
end

defmodule Logproto.LabelResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          values: [String.t()]
        }
  defstruct [:values]

  field(:values, 1, repeated: true, type: :string)
end

defmodule Logproto.Stream do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          labels: String.t(),
          entries: [Logproto.Entry.t()]
        }
  defstruct [:labels, :entries]

  field(:labels, 1, type: :string)
  field(:entries, 2, repeated: true, type: Logproto.Entry)
end

defmodule Logproto.Entry do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          timestamp: Google.Protobuf.Timestamp.t() | nil,
          line: String.t()
        }
  defstruct [:timestamp, :line]

  field(:timestamp, 1, type: Google.Protobuf.Timestamp)
  field(:line, 2, type: :string)
end

defmodule Logproto.TailRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          query: String.t(),
          regex: String.t(),
          delayFor: non_neg_integer,
          limit: non_neg_integer,
          start: Google.Protobuf.Timestamp.t() | nil
        }
  defstruct [:query, :regex, :delayFor, :limit, :start]

  field(:query, 1, type: :string)
  field(:regex, 2, type: :string)
  field(:delayFor, 3, type: :uint32)
  field(:limit, 4, type: :uint32)
  field(:start, 5, type: Google.Protobuf.Timestamp)
end

defmodule Logproto.TailResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          stream: Logproto.Stream.t() | nil,
          droppedStreams: [Logproto.DroppedStream.t()]
        }
  defstruct [:stream, :droppedStreams]

  field(:stream, 1, type: Logproto.Stream)
  field(:droppedStreams, 2, repeated: true, type: Logproto.DroppedStream)
end

defmodule Logproto.DroppedStream do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          from: Google.Protobuf.Timestamp.t() | nil,
          to: Google.Protobuf.Timestamp.t() | nil,
          labels: String.t()
        }
  defstruct [:from, :to, :labels]

  field(:from, 1, type: Google.Protobuf.Timestamp)
  field(:to, 2, type: Google.Protobuf.Timestamp)
  field(:labels, 3, type: :string)
end

defmodule Logproto.TimeSeriesChunk do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          from_ingester_id: String.t(),
          user_id: String.t(),
          labels: [Logproto.LabelPair.t()],
          chunks: [Logproto.Chunk.t()]
        }
  defstruct [:from_ingester_id, :user_id, :labels, :chunks]

  field(:from_ingester_id, 1, type: :string)
  field(:user_id, 2, type: :string)
  field(:labels, 3, repeated: true, type: Logproto.LabelPair)
  field(:chunks, 4, repeated: true, type: Logproto.Chunk)
end

defmodule Logproto.LabelPair do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t()
        }
  defstruct [:name, :value]

  field(:name, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Logproto.Chunk do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          data: binary
        }
  defstruct [:data]

  field(:data, 1, type: :bytes)
end

defmodule Logproto.TransferChunksResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Logproto.Direction do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:FORWARD, 0)
  field(:BACKWARD, 1)
end
