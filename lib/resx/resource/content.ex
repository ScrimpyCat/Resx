defmodule Resx.Resource.Content do
    defstruct [:type, :data]

    alias Resx.Resource.Content

    @type type :: atom | [atom]
    @type t :: %Content{
        type: type,
        data: any
    }
end
