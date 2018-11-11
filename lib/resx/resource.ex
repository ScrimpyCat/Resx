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
    @spec open(t | Resx.ref) :: { :ok, Resource.t(Content.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def open(resource), do: adapter_call([resource], :open)

    @spec stream(t | Resx.ref) :: { :ok, Resource.t(Content.Stream.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def stream(resource), do: adapter_call([resource], :stream)

    @spec exists?(t | Resx.ref) :: { :ok, boolean } | Resx.error(Resx.reference_error)
    def exists?(resource), do: adapter_call([resource], :exists?)

    @spec alike?(t | Resx.ref, t | Resx.ref) :: boolean
    def alike?(resource_a, resource_b), do: adapter_call([resource_a, resource_b], :alike?)

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
      to `:crypto.hash/2`, or a function that accepts a binary and returns any term.
      Valid function formats are any callback variant, see `Resx.Callback` for more
      information.

      If the requested hash is the same as the checksum found in the resource, then
      that checksum will be returned without rehashing the resource content.

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :crc32, { :erlang, :crc32, 1 } })
        { :crc32, 1244230748 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :crc32, { :erlang, :crc32, [] } })
        { :crc32, 1244230748 }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :md5, { :crypto, :hash, [:md5] } })
        { :md5, <<11, 42, 163, 52, 185, 160, 71, 166, 238, 225, 51, 70, 234, 139, 186, 19>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :hmac_md5_5, { :crypto, :hmac, [:md5, "secret", 5], 2 } })
        { :hmac_md5_5, <<146, 5, 93, 75, 11>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, :md5)
        { :md5, <<11, 42, 163, 52, 185, 160, 71, 166, 238, 225, 51, 70, 234, 139, 186, 19>> }

        iex> Resx.Resource.hash(%Resx.Resource.Content{ type: ["text/plain"], data: "Hello" }, { :base64, &Base.encode64/1 })
        { :base64, "g2gCbAAAAAFtAAAACnRleHQvcGxhaW5qbQAAAAVIZWxsbw==" }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :md5)
        { :md5, <<11, 42, 163, 52, 185, 160, 71, 166, 238, 225, 51, 70, 234, 139, 186, 19>> }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :foo)
        { :foo, 1 }

        iex> Resx.Resource.hash(%Resx.Resource{ reference: %Resx.Resource.Reference{ integrity: %Resx.Resource.Reference.Integrity{ checksum: { :foo, 1 }, timestamp: 0 }, adapter: nil, repository: nil }, content: %Resx.Resource.Content{ type: ["text/plain"], data: "Hello" } }, :md5)
        { :md5, <<11, 42, 163, 52, 185, 160, 71, 166, 238, 225, 51, 70, 234, 139, 186, 19>> }
    """
    @spec hash(t | content, Integrity.algo | { Integrity.algo, Callback.callback(binary, any) }) :: Integrity.checksum
    def hash(%Resource{ reference: %{ integrity: %{ checksum: checksum = { algo, _ } } } }, { algo, _ }), do: checksum
    def hash(%Resource{ reference: %{ integrity: %{ checksum: checksum = { algo, _ } } } }, algo), do: checksum
    def hash(resource, { algo, fun }) do
        { algo, Callback.call(fun, [to_binary(resource)]) }
    end
    def hash(resource, algo) do
        { algo, :crypto.hash(algo, to_binary(resource)) }
    end

    defp to_binary(%Resource{ content: content }), do: to_binary(content)
    defp to_binary(content), do: :erlang.term_to_binary({ content.type, Content.data(content) })
end
