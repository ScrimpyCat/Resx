defmodule Resx.Resource.Content do
    @moduledoc """
      The content of a resource.

        %Resx.Resource.Content{
            type: :html,
            data: "<p>Hello</p>"
        }
    """

    defstruct [:type, :data]

    alias Resx.Resource.Content

    @type type :: atom | [atom]
    @type t :: %Content{
        type: type,
        data: any
    }
end
