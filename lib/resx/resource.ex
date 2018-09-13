defmodule Resx.Resource do
    defstruct [:content]

    alias Resx.Resource

    @type t :: %Resource{
        content: Resource.Content.t
    }
end
