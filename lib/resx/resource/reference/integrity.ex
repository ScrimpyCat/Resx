defmodule Resx.Resource.Reference.Integrity do
    @moduledoc """
      The integrity of a resource.

        %Resx.Resource.Reference.Integrity{
            checksum: { :crc32, 3829359344 },
            timestamp: 1536855009
        }
    """

    @enforce_keys [:checksum, :timestamp]

    defstruct [:checksum, :timestamp]

    alias Resx.Resource.Reference.Integrity

    @type algo :: atom
    @type checksum :: { algo, any }
    @type t :: %Integrity{
        checksum: checksum,
        timestamp: integer
    }
end
