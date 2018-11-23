defmodule Resx.Resource do
    @moduledoc """
      The resource representation.
    """

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity
    alias Resx.Callback

    @type attribute_key :: atom | String.t
    @type content :: Content.t | Content.Stream.t
    @type hash_state :: any
    @type streamable_hasher :: { Integrity.algo, initializer :: Callback.callback(Integrity.algo, hash_state), updater :: Callback.callback(hash_state, binary, hash_state), finaliser :: Callback.callback(hash_state, any) }
    @type hasher :: { Integrity.algo, Callback.callback(binary, any) }

    @enforce_keys [:reference, :content]

    defstruct [:reference, :content, meta: []]

    @type t :: t(content)

    @type t(content) :: %Resource{
        reference: Reference.t,
        content: content,
        meta: keyword
    }

    defp ref(%Resource{ reference: reference }), do: reference
    defp ref(reference), do: reference

    defp adapter(reference) do
        case Resx.producer(reference) do
            nil -> { :error, { :invalid_reference, "no producer for URI (#{reference})" } }
            adapter -> { :ok, adapter }
        end
    end

    defp adapter_call(resources, op, arg \\ [])
    defp adapter_call([input|inputs], op, args), do: adapter_call(inputs, op, [ref(input)|args])
    defp adapter_call([], op, args) do
        args = [reference|_] = Enum.reverse(args)
        case adapter(reference) do
            { :ok, adapter } -> apply(adapter, op, args)
            error -> error
        end
    end

    @doc """
      Open a resource from a pre-existing resource or a resource reference.
    """
    @spec open(t | Resx.ref, keyword) :: { :ok, Resource.t(Content.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def open(resource, opts \\ []), do: adapter_call([resource, opts], :open)

    @doc """
      Stream a resource from a pre-existing resource or a resource reference.
    """
    @spec stream(t | Resx.ref, keyword) :: { :ok, Resource.t(Content.Stream.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def stream(resource, opts \\ []), do: adapter_call([resource, opts], :stream)

    @doc """
      Check whether a resource or resource reference exists.
    """
    @spec exists?(t | Resx.ref) :: { :ok, boolean } | Resx.error(Resx.reference_error)
    def exists?(resource), do: adapter_call([resource], :exists?)

    @doc """
      Check if two resources or resource references point to the same resource.
    """
    @spec alike?(t | Resx.ref, t | Resx.ref) :: boolean
    def alike?(resource_a, resource_b), do: adapter_call([resource_a, resource_b], :alike?)

    @doc """
      Retrieve the URI for a resource or resource reference.
    """
    @spec uri(t | Reference.t) :: { :ok, Resx.uri } | Resx.error(Resx.resource_error | Resx.reference_error)
    def uri(resource), do: adapter_call([resource], :resource_uri)

    @spec attribute(t | Resx.ref, attribute_key) :: { :ok, any } | Resx.error(Resx.resource_error | Resx.reference_error | :unknown_key)
    def attribute(resource, field), do: adapter_call([resource, field], :resource_attribute)

    @spec attributes(t | Resx.ref) :: { :ok, %{ optional(attribute_key) => any } } | Resx.error(Resx.resource_error | Resx.reference_error)
    def attributes(resource), do: adapter_call([resource], :resource_attributes)

    @spec attribute_keys(t | Resx.ref) :: { :ok, [attribute_key] } | Resx.error(Resx.resource_error | Resx.reference_error)
    def attribute_keys(resource), do: adapter_call([resource], :resource_attribute_keys)

    @doc """
      Compute a hash of the resource content using the default hashing function.

      The default hashing function can be configured by giving a `:hash` option in
      your config.

        config :resx,
            hash: { :crc32, { :erlang, :crc32, 1 } }

      See `hash/2` for more information.
    """
    @spec hash(t | content) :: Integrity.checksum
    def hash(resource) do
        hash(resource, Application.get_env(:resx, :hash, :sha))
    end

    @doc """
      Compute a hash of the resource content.

      Meta information and resource references are not included in the hash.

      Hashing algorithms can take the form of either an atom that is a valid option
      to `:crypto.hash/2`, or a tuple of type `hasher` or `streamable_hasher` to
      provide a custom hashing function. Valid function formats are any callback
      variant, see `Resx.Callback` for more information.

      __Note:__ If the resource content is streamable and a `hasher` is provided for
      the algo, then the entire content will be decomposed first. If the algo is a
      `streamable_hasher` then no decomposition will take place.

      The inputs to the initialiser function of a `streamable_hasher` are optional.
      The rest are all required.

      If the requested hash is the same as the checksum found in the resource, then
      that checksum will be returned without rehashing the resource content.

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :crc32, { :erlang, :crc32, 1 } })
        { :crc32, 4157704578 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :crc32, { :erlang, :crc32, [] } })
        { :crc32, 4157704578 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :md5, { :crypto, :hash, [:md5] } })
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content.Stream{ type: ["text/plain"], data: ["He", "l", "lo"] }, { :md5, { :crypto, :hash, [:md5] } })
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :md5, { :crypto, :hash_init, 1 }, { :crypto, :hash_update, 2 }, { :crypto, :hash_final, 1 } })
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content.Stream{ type: ["text/plain"], data: ["He", "l", "lo"] }, { :md5, { :crypto, :hash_init, 1 }, { :crypto, :hash_update, 2 }, { :crypto, :hash_final, 1 } })
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, :md5)
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content.Stream{ type: ["text/plain"], data: ["He", "l", "lo"] }, :md5)
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :hmac_md5_5, { :crypto, :hmac, [:md5, "secret", 5], 2 } })
        { :hmac_md5_5, <<243, 134, 128, 59, 99>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content.Stream{ type: ["text/plain"], data: ["He", "l", "lo"] }, { :hmac_md5_5, { :crypto, :hmac, [:md5, "secret", 5], 2 } })
        { :hmac_md5_5, <<243, 134, 128, 59, 99>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :hmac_md5_5, { :crypto, :hmac_init, [:md5, "secret"], nil }, { :crypto, :hmac_update, 2 }, { :crypto, :hmac_final_n, [5], 0 } })
        { :hmac_md5_5, <<243, 134, 128, 59, 99>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content.Stream{ type: ["text/plain"], data: ["He", "l", "lo"] }, { :hmac_md5_5, { :crypto, :hmac_init, [:md5, "secret"], nil }, { :crypto, :hmac_update, 2 }, { :crypto, :hmac_final_n, [5], 0 } })
        { :hmac_md5_5, <<243, 134, 128, 59, 99>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :base64, &Base.encode64/1 })
        { :base64, "SGVsbG8=" }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :md5)
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :foo)
        { :foo, 1 }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :md5)
        { :md5, <<139, 26, 153, 83, 196, 97, 18, 150, 168, 39, 171, 248, 196, 120, 4, 215>> }
    """
    @spec hash(t | content, Integrity.algo | hasher | streamable_hasher) :: Integrity.checksum
    def hash(%Resource{ reference: %{ integrity: %{ checksum: checksum = { algo, _ } } } }, { algo, _ }), do: checksum
    def hash(%Resource{ reference: %{ integrity: %{ checksum: checksum = { algo, _ } } } }, algo), do: checksum
    def hash(resource, { algo, initialiser, updater, finaliser }) do
        hash = Callback.call(finaliser, [content_reducer(resource) |> Callback.call([Callback.call(initialiser, [algo], :optional), &Callback.call(updater, [&2, &1])])])
        { algo, hash }
    end
    def hash(resource, { algo, fun }) do
        data = content_reducer(resource) |> Callback.call([<<>>, &(&2 <> &1)])
        { algo, Callback.call(fun, [data]) }
    end
    def hash(resource, algo) do
        hash = content_reducer(resource) |> Callback.call([:crypto.hash_init(algo), &:crypto.hash_update(&2, &1)]) |> :crypto.hash_final
        { algo, hash }
    end

    defp content_reducer(%Resource{ content: content }), do: content_reducer(content)
    defp content_reducer(content), do: Content.reducer(content)
end
