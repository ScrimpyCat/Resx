defmodule Resx.Resource.Content do
    @moduledoc """
      The content of a resource.

        %Resx.Resource.Content{
            type: ["text/html]",
            data: "<p>Hello</p>"
        }
    """

    alias Resx.Resource.Content

    @enforce_keys [:type, :data]

    defstruct [:type, :data]

    @type mime :: String.t
    @type type :: [mime, ...]
    @type t :: %Content{
        type: type,
        data: any
    }

    @doc """
      Retrieve the content data.
    """
    @spec data(t | Content.Stream.t) :: any
    def data(%Content{ data: data }), do: data
    def data(%Content.Stream{ data: data }), do: Enum.join(data)

    @doc """
      Make some content explicit.
    """
    @spec new(t | Content.Stream.t) :: t
    def new(content), do: %Content{ type: content.type, data: data(content) }
end
