defmodule Resx.Resource do
    @moduledoc """
      The resource representation.
    """

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

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

    defmodule OpenError do
        defexception [:type, :reason, :reference]

        @impl Exception
        def exception({ reference, { type, reason } }) do
            %OpenError{
                type: type,
                reason: reason,
                reference: reference
            }
        end

        @impl Exception
        def message(%{ type: :internal, reason: reason }), do: "internal error: #{inspect reason}"
        def message(%{ type: :invalid_reference, reason: reason }), do: "invalid reference: #{inspect reason}"
        def message(%{ type: :unknown_resource, reason: reason }), do: "unknown resource: #{inspect reason}"
    end

    defp adapter(reference) do
        case Resx.producer(reference) do
            nil -> { :error, { :invalid_reference, "no producer for URI (#{reference})" } }
            adapter -> { :ok, adapter }
        end
    end

    defp adapter_call(resources, op, arg \\ [])
    defp adapter_call([input|inputs], op, args), do: adapter_call(inputs, op, [Resx.ref(input)|args])
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
    def open(resource, opts \\ []) do
        with { :open, error = { :error, { :unknown_resource, _ } } } <- { :open, adapter_call([resource, opts], :open) },
             { :source_compatibility, { :compatible, :default }, _ } <- { :source_compatibility, adapter_call([resource], :source_compatibility), error },
             { :source, { :ok, source }, error } when not is_nil(source) <- { :source, source(resource), error },
             { :open, { :ok, source } } <- { :open, open(source) },
             { :adapter, { :ok, adapter } } <- { :adapter, adapter(resource) },
             { :store, { :ok, resource } } <- { :store, store(source, adapter, adapter.prepare_store(resource)) } do
                { :ok, %{ resource | content: Content.new(resource.content) } }
        else
            { :open, result } -> result
            { :source_compatibility, _, error } -> error
            { :source, nil, error } -> error
            { :source, error, _ } -> error
            { :adapter, error } -> error
            { :store, error } -> error
        end
    end

    @doc """
      Open a resource from a pre-existing resource or a resource reference.

      Raises a `Resx.Resource.OpenError` if the resource could not be opened.

      For more details see `Resx.Resource.open/2`.
    """
    @spec open!(t | Resx.ref, keyword) :: Resource.t(Content.t) | no_return
    def open!(resource, opts \\ []) do
        case open(resource, opts) do
            { :ok, resource } -> resource
            { :error, error } -> raise OpenError, { resource, error }
        end
    end

    @doc """
      Stream a resource from a pre-existing resource or a resource reference.
    """
    @spec stream(t | Resx.ref, keyword) :: { :ok, Resource.t(Content.Stream.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def stream(resource, opts \\ []) do
        with { :stream, error = { :error, { :unknown_resource, _ } } } <- { :stream, adapter_call([resource, opts], :stream) },
             { :source_compatibility, { :compatible, :default }, _ } <- { :source_compatibility, adapter_call([resource], :source_compatibility), error },
             { :source, { :ok, source }, error } when not is_nil(source) <- { :source, source(resource), error },
             { :stream, { :ok, source } } <- { :stream, stream(source) },
             { :adapter, { :ok, adapter } } <- { :adapter, adapter(resource) },
             { :store, { :ok, resource } } <- { :store, store(source, adapter, adapter.prepare_store(resource)) } do
                { :ok, %{ resource | content: Content.Stream.new(resource.content) } }
        else
            { :stream, result } -> result
            { :source_compatibility, _, error } -> error
            { :source, nil, error } -> error
            { :source, error, _ } -> error
            { :adapter, error } -> error
            { :store, error } -> error
        end
    end

    @doc """
      Stream a resource from a pre-existing resource or a resource reference.

      Raises a `Resx.Resource.OpenError` if the resource could not be streamed.

      For more details see `Resx.Resource.stream/2`.
    """
    @spec stream!(t | Resx.ref, keyword) :: Resource.t(Content.Stream.t) | no_return
    def stream!(resource, opts \\ []) do
        case stream(resource, opts) do
            { :ok, resource } -> resource
            { :error, error } -> raise OpenError, { resource, error }
        end
    end

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
      Get the source of the current resource or resource reference.

      It will return `{ :ok, nil }` if there is no source.
    """
    @spec source(t | Resx.ref) :: { :ok, Resx.ref | nil } | Resx.error(Resx.reference_error)
    def source(resource), do: adapter_call([resource], :source)

    @doc """
      Retrieve the URI for a resource or resource reference.
    """
    @spec uri(t | Reference.t) :: { :ok, Resx.uri } | Resx.error(Resx.resource_error | Resx.reference_error)
    def uri(resource), do: adapter_call([resource], :resource_uri)

    @doc """
      Retrieve the attribute for a resource or resource reference.
    """
    @spec attribute(t | Resx.ref, attribute_key) :: { :ok, any } | Resx.error(Resx.resource_error | Resx.reference_error | :unknown_key)
    def attribute(resource, field), do: adapter_call([resource, field], :resource_attribute)

    @doc """
      Retrieve the attributes for a resource or resource reference.
    """
    @spec attributes(t | Resx.ref) :: { :ok, %{ optional(attribute_key) => any } } | Resx.error(Resx.resource_error | Resx.reference_error)
    def attributes(resource), do: adapter_call([resource], :resource_attributes)

    @doc """
      Retrieve the attribute keys for a resource or resource reference.
    """
    @spec attribute_keys(t | Resx.ref) :: { :ok, [attribute_key] } | Resx.error(Resx.resource_error | Resx.reference_error)
    def attribute_keys(resource), do: adapter_call([resource], :resource_attribute_keys)

    @doc """
      Transform the resource.

      If a resource reference is given, a stream will be opened to that resource.

      For more details see `Resx.Transformer.apply/2`.
    """
    @spec transform(t | Resx.ref, module, keyword) :: { :ok, t } | Resx.error(Resx.resource_error | Resx.reference_error)
    def transform(resource, transformer, opts \\ [])
    def transform(resource = %Resource{}, transformer, opts), do: Resx.Transformer.apply(resource, transformer, opts)
    def transform(reference, transformer, opts) do
        case stream(reference) do
            { :ok, resource } -> Resx.Transformer.apply(resource, transformer, opts)
            error -> error
        end
    end

    @doc """
      Transform the resource.

      If a resource reference is given, a stream will be opened to that resource.

      Raises a `Resx.Transformer.TransformError` if the transformation cannot be applied,
      or a `Resx.Resource.OpenError` if the resource could not be opened.

      For more details see `Resx.Transformer.apply!/2`.
    """
    @spec transform!(t | Resx.ref, module, keyword) :: t | no_return
    def transform!(resource, transformer, opts \\ [])
    def transform!(resource = %Resource{}, transformer, opts), do: Resx.Transformer.apply!(resource, transformer, opts)
    def transform!(reference, transformer, opts), do: stream!(reference) |> Resx.Transformer.apply!(transformer, opts)

    @doc """
      Store the resource.

      If a resource reference is given, a stream will be opened to that resource.

      For more details see `Resx.Storer.save/2`.
    """
    @spec store(t | Resx.ref, module, keyword) :: { :ok, t } | Resx.error(Resx.resource_error | Resx.reference_error)
    def store(resource, storer, opts \\ [])
    def store(resource = %Resource{}, storer, opts), do: Resx.Storer.save(resource, storer, opts)
    def store(reference, storer, opts) do
        case stream(reference) do
            { :ok, resource } -> Resx.Storer.save(resource, storer, opts)
            error -> error
        end
    end

    @doc """
      Store the resource.

      If a resource reference is given, a stream will be opened to that resource.

      Raises a `Resx.Storer.StoreError` if the resource cannot be saved,
      or a `Resx.Resource.OpenError` if the resource could not be opened.

      For more details see `Resx.Storer.save!/2`.
    """
    @spec store!(t | Resx.ref, module, keyword) :: t | no_return
    def store!(resource, storer, opts \\ [])
    def store!(resource = %Resource{}, storer, opts), do: Resx.Storer.save!(resource, storer, opts)
    def store!(reference, storer, opts), do: stream!(reference) |> Resx.Storer.save!(storer, opts)

    @doc """
      Discard the resource.

      Only resources or resource references that implement the `Resx.Storer` behaviour
      should be passed to this.
    """
    @spec discard(t | Resx.ref, keyword) :: :ok | Resx.error(Resx.resource_error | Resx.reference_error)
    def discard(resource, opts \\ []), do: adapter_call([resource, opts], :discard)

    @doc """
      Check what kind of reference this resource or resource reference is.

        iex> Resx.Resource.open!("data:,foo") |> Resx.Resource.kind?(Resx.Producer)
        true

        iex> Resx.Resource.kind?("data:,foo", Resx.Producer)
        true

        iex> Resx.Resource.kind?("data:,foo", Resx.Producers.Data)
        true

        iex> Resx.Resource.kind?("data:,foo", Resx.Storer)
        false

        iex> Resx.Resource.kind?("data:,foo", Resx.Transformer)
        false
    """
    @spec kind?(t | Resx.ref, module) :: boolean
    def kind?(resource, Resx.Transformer) do
        case adapter(resource) do
            { :ok, Resx.Producers.Transform } -> true
            _ -> false
        end
    end
    def kind?(resource, behaviour) do
        case adapter(resource) do
            { :ok, ^behaviour } -> true
            { :ok, adapter } -> adapter.__info__(:attributes) |> Enum.any?(&(&1 == { :behaviour, [behaviour] }))
            _ -> false
        end
    end

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
      variant, see `Callback` for more information.

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

defimpl Enumerable, for: [Resx.Resource, Resx.Resource.Reference] do
    def reduce(_, { :halt, acc }, _), do: { :halted, acc }
    def reduce(resource, { :suspend, acc }, reducer), do: { :suspended, acc, &reduce(resource, &1, reducer) }
    def reduce(resource, { :cont, acc }, reducer) do
        { tag, acc } = reducer.(resource, acc)
        case Resx.Resource.source(resource) do
            { :ok, source } when not is_nil(source) -> reduce(source, { tag, acc }, reducer)
            _ -> { :done, acc }
        end
    end

    def count(_), do: { :error, __MODULE__ }

    def member?(_, _), do: { :error, __MODULE__ }

    def slice(_), do: { :error, __MODULE__ }
end
