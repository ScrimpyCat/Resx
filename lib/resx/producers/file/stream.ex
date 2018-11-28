defmodule Resx.Producers.File.Stream do
    @moduledoc false

    @enforce_keys [:stream, :node]

    defstruct [:stream, :node]

    @type t :: %Resx.Producers.File.Stream{
        stream: File.Stream.t,
        node: node
    }

    defimpl Collectable do
        def into(%{ stream: stream, node: node }), do: Resx.Producers.File.call(node, Collectable, :into, [stream], path: stream.path, exception: true)
    end

    defimpl Enumerable do
        def count(%{ stream: stream, node: node }), do: Resx.Producers.File.call(node, Enumerable, :count, [stream], path: stream.path, exception: true)

        def member?(%{ stream: stream, node: node }, element), do: Resx.Producers.File.call(node, Enumerable, :member?, [stream, element], path: stream.path, exception: true)

        def reduce(%{ stream: stream, node: node }, acc, reducer), do: Resx.Producers.File.call(node, Enumerable, :reduce, [stream, acc, reducer], path: stream.path, exception: true)

        def slice(%{ stream: stream, node: node }), do: Resx.Producers.File.call(node, Enumerable, :slice, [stream], path: stream.path, exception: true)
    end
end
