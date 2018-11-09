defmodule Resx.Resource.Content.Stream do
    @moduledoc """
      The streamable content of a resource.

        %Resx.Resource.Content.Stream{
            type: ["text/html]",
            data: ["<p>", "Hello", "</p>"]
        }
    """

    alias Resx.Resource.Content

    @enforce_keys [:type, :data]

    defstruct [:type, :data]

    @type mime :: String.t
    @type type :: [mime, ...]
    @type t :: %Content.Stream{
        type: type,
        data: Enumerable.t
    }

    defimpl Enumerable do
        def count(%{ data: data }), do: Enumerable.count(data)

        def member?(%{ data: data }, element), do: Enumerable.member?(data, element)

        def reduce(%{ data: data }, acc, reducer), do: Enumerable.reduce(data, acc, reducer)

        def slice(%{ data: data }), do: Enumerable.slice(data)
    end

    @doc """
      Make some content streamable.
    """
    @spec new(t | Content.t) :: t
    def new(%Content{ type: type, data: data }), do: %Content.Stream{ type: type, data: [data] }
    def new(content), do: content
end
