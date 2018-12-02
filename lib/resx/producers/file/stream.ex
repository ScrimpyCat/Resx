defmodule Resx.Producers.File.Stream do
    @moduledoc false

    @enforce_keys [:stream, :node, :path]

    defstruct [:stream, :node, :path]

    @type t :: %Resx.Producers.File.Stream{
        stream: Enumerable.t,
        node: node,
        path: String.t
    }

    defimpl Collectable do
        def into(%{ stream: stream, node: node, path: path }), do: Resx.Producers.File.call(node, Collectable, :into, [stream], path: path, exception: true)
    end

    defimpl Enumerable do
        def count(%{ stream: stream, node: node, path: path }), do: Resx.Producers.File.call(node, Enumerable, :count, [stream], path: path, exception: true)

        def member?(%{ stream: stream, node: node, path: path }, element), do: Resx.Producers.File.call(node, Enumerable, :member?, [stream, element], path: path, exception: true)

        def reduce(%{ stream: stream, node: node, path: path }, acc, reducer), do: Resx.Producers.File.call(node, Enumerable, :reduce, [stream, acc, reducer], path: path, exception: true)

        def slice(%{ stream: stream, node: node, path: path }), do: Resx.Producers.File.call(node, Enumerable, :slice, [stream], path: path, exception: true)
    end
end
