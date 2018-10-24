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
end
