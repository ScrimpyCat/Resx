defmodule Resx.Resource.Reference.Integrity do
    @moduledoc """
      The integrity of a resource.

        %Resx.Resource.Reference.Integrity{
            checksum: { :crc32, 3829359344 },
            timestamp: DateTime.utc_now
        }
    """

    alias Resx.Resource.Reference.Integrity

    @enforce_keys [:timestamp]

    defstruct [:checksum, :timestamp]

    @type algo :: atom
    @type checksum :: { algo, any }
    @type t :: %Integrity{
        checksum: nil | checksum,
        timestamp: DateTime.t
    }

    @doc """
      Compare two integrities.

      The result is a tuple with the first element being the result of the
      comparison between the two checksums. If the checksums are equal then it will
      be true, if the checksum algorithms are the same but the hashes are not equal
      it will be false, otherwise if the checksums cannot be compared it will be
      `nil`. The second element will be the result of a `DateTime.compare/2` on the
      two timestamps.

        iex> Resx.Resource.Reference.Integrity.compare(%Resx.Resource.Reference.Integrity{ timestamp: DateTime.from_unix!(0) }, %Resx.Resource.Reference.Integrity{ timestamp: DateTime.from_unix!(0) })
        { nil, :eq }

        iex> Resx.Resource.Reference.Integrity.compare(%Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: DateTime.from_unix!(1) }, %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: DateTime.from_unix!(0) })
        { true, :gt }

        iex> Resx.Resource.Reference.Integrity.compare(%Resx.Resource.Reference.Integrity{ checksum: { :foo, 2 }, timestamp: DateTime.from_unix!(0) }, %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: DateTime.from_unix!(1) })
        { false, :lt }

        iex> Resx.Resource.Reference.Integrity.compare(%Resx.Resource.Reference.Integrity{ checksum: { :bar, 1 }, timestamp: DateTime.from_unix!(0) }, %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: DateTime.from_unix!(0) })
        { nil, :eq }

    """
    @spec compare(t, t) :: { checksum :: nil | boolean, timestamp :: :lt | :eq | :gt }
    def compare(%Integrity{ checksum: nil, timestamp: a }, %Integrity{ checksum: nil, timestamp: b }), do: { nil, DateTime.compare(a, b)}
    def compare(%Integrity{ checksum: checksum, timestamp: a }, %Integrity{ checksum: checksum, timestamp: b }), do: { true, DateTime.compare(a, b)}
    def compare(%Integrity{ checksum: { algo, _ }, timestamp: a }, %Integrity{ checksum: { algo, _ }, timestamp: b }), do: { false, DateTime.compare(a, b)}
    def compare(%Integrity{ timestamp: a }, %Integrity{ timestamp: b }), do: { nil, DateTime.compare(a, b)}
end
