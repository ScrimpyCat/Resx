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

    @type t :: %Content.Stream{
        type: Content.type,
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

    @doc """
      Combine a content stream into a collectable.

      If the collectable is a bitstring, this will only combine the content into
      a bitstring if it is possible to do so. Otherwise it will just return a list.
    """
    @spec combine(t, Collectable.t) :: Collectable.t
    def combine(content, collectable \\ [])
    def combine(content, collectable) when is_bitstring(collectable) do
        Enum.reduce(content.data, { [], true }, fn
            chunk, { list, true } when is_bitstring(chunk) -> { [chunk|list], true }
            chunk, { list, _ } -> { [chunk|list], false }
        end)
        |> case do
            { list, true } -> Enum.reverse(list) |> Enum.into(<<>>)
            { list, false } -> Enum.reverse(list)
        end
    end
    def combine(content, collectable), do: Enum.into(content.data, collectable)
end
