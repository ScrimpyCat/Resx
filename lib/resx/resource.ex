defmodule Resx.Resource do
    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @enforce_keys [:reference, :content]

    defstruct [:reference, :content, meta: []]

    @type t :: %Resource{
        reference: Reference.t,
        content: Content.t,
        meta: keyword
    }

    def open(%Resource{ reference: reference }), do: reference
    def open(reference) do
        case Resx.producer(reference) do
            nil -> { :error, { :invalid_reference, "no producer for URI (#{reference})" } }
            adapter -> adapter.open(reference)
        end
    end

    @doc """
      Compute a hash of the resource content using the default hashing function.

      See `hash/2` for more information.
    """
    @spec hash(t | Content.t) :: Integrity.checksum
    def hash(resource) do
        hash(resource, Application.get_env(:resx, :hash, :sha))
    end

    @doc """
      Compute a hash of the resource content.

      Meta information and resource references are not included in the hash.

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, { :crc32, { :erlang, :crc32, 1 } })
        { :crc32, 1916479825 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, { :crc32, { :erlang, :crc32, [] } })
        { :crc32, 1916479825 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, { :md5, { :crypto, :hash, [:md5] } })
        { :md5, <<182, 117, 169, 117, 204, 18, 203, 145, 170, 93, 254, 5, 255, 81, 147, 6>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, { :hmac_md5_5, { :crypto, :hmac, [:md5, "secret", 5], 2 } })
        { :hmac_md5_5, <<191, 168, 210, 216, 244>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, :md5)
        { :md5, <<182, 117, 169, 117, 204, 18, 203, 145, 170, 93, 254, 5, 255, 81, 147, 6>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: :string, data: "Hello" }, { :base64, &Base.encode64/1 })
        { :base64, "g2gCZAAGc3RyaW5nbQAAAAVIZWxsbw==" }
    """
    @spec hash(t | Content.t, Integrity.algo | { Integrity.algo, fun | mfa | { module, atom, list } | { module, atom, list, non_neg_integer } }) :: Integrity.checksum
    def hash(resource, { algo, { module, fun, args, index } }) do
        { algo, apply(module, fun, List.insert_at(args, index, to_binary(resource))) }
    end
    def hash(resource, { algo, { module, fun, 1 } }) do
        { algo, apply(module, fun, [to_binary(resource)]) }
    end
    def hash(resource, { algo, { module, fun, args } }) do
        { algo, apply(module, fun, args ++ [to_binary(resource)]) }
    end
    def hash(resource, { algo, fun }) do
        { algo, fun.(to_binary(resource)) }
    end
    def hash(resource, algo) do
        { algo, :crypto.hash(algo, to_binary(resource)) }
    end

    defp to_binary(%Resource{ content: content }), do: to_binary(content)
    defp to_binary(%Content{ type: type, data: data }), do: :erlang.term_to_binary({ type, data })
end
