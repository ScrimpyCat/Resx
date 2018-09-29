defmodule Resx.Resource.Reference do
    @moduledoc """
      The reference of a resource.
    """

    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @enforce_keys [:adapter, :repository, :integrity]

    defstruct [:adapter, :repository, :integrity]

    @type t :: %Reference{
        adapter: module,
        repository: any,
        integrity: Integrity.t
    }
end
