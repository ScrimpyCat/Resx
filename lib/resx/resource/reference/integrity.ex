defmodule Resx.Resource.Reference.Integrity do
    @moduledoc """
      The integrity of a resource.

        %Resx.Resource.Reference.Integrity{
            checksum: { :crc32, 3829359344 },
            timestamp: 1536855009
        }
    """

    alias Resx.Resource.Reference.Integrity

    @enforce_keys [:timestamp]

    defstruct [:checksum, :timestamp]

    @type algo :: atom
    @type checksum :: { algo, any }
    @type t :: %Integrity{
        checksum: nil | checksum,
        timestamp: integer
    }
end
