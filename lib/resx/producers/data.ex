defmodule Resx.Producers.Data do
    @moduledoc """
      A producer to handle data URIs.

        Resx.Producers.Data.open("data:text/plain;base64,SGVsbG8sIFdvcmxkIQ%3D%3D")

      ### Media Types

      If an error is being returned when attempting to open a data URI due to
      `{ :invalid_reference, "invalid media type: \#{type}" }`, the MIME type
      will need to be added to the config.

      ### Attributes

      Data URI attributes will be able to be accessed as resource attributes
      `Resx.Resource.attributes/1`
    """
    use Resx.Producer

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    defp to_data(%Reference{ repository: repo }), do: { :ok, repo }
    defp to_data(%URI{ scheme: "data", path: path }) do
        with [tokens, data] <- String.split(path, ",", parts: 2),
             [type|tokens] <- String.split(tokens, ";") do
                decode(type, tokens, data)
        else
            _ -> { :error, { :invalid_reference, "invalid data URI format" } }
        end
    end
    defp to_data(uri) when is_binary(uri), do: URI.decode(uri) |> URI.parse |> to_data
    defp to_data(_), do: { :error, { :invalid_reference, "not a data reference" } }

    defp decode("", [], data), do: decode("text/plain", ["charset=US-ASCII"], data)
    defp decode("", tokens, data), do: decode("text/plain", tokens, data)
    defp decode(type, tokens, data) do
        if MIME.valid?(type) do
            { attributes, decoder } = Enum.reduce(tokens, { [], &({ :ok, &1 }) }, fn
                "base64", { attributes, _ } ->
                    decoder = fn data ->
                        case Base.decode64(data) do
                            { :ok, data } -> { :ok, data }
                            _ -> { :error, { :invalid_reference, "data is not base64" } }
                        end
                    end
                    { attributes, decoder }
                params, { attributes, decoder } ->
                    [key, value] = String.split(params, "=")
                    { [{ key, value }|attributes], decoder }
            end)

            case decoder.(data) do
                { :ok, data } -> { :ok, { type, Map.new(attributes), data } }
                error -> error
            end
        else
            { :error, { :invalid_reference, "invalid media type: #{type}" } }
        end
    end

    @impl Resx.Producer
    def schemes(), do: ["data"]

    @impl Resx.Producer
    def open(reference, _ \\ []) do
        case to_data(reference) do
            { :ok, { type, attributes, data } } -> { :ok, new(data, type, attributes) }
            error -> error
        end
    end

    @impl Resx.Producer
    def exists?(reference) do
        case to_data(reference) do
            { :ok, _ } -> { :ok, true }
            error -> error
        end
    end

    @impl Resx.Producer
    def alike?(a, b) do
        with { :a, { :ok, data } } <- { :a, to_data(a) },
             { :b, { :ok, ^data } } <- { :b, to_data(b) } do
                true
        else
            _ -> false
        end
    end

    @impl Resx.Producer
    def resource_uri(reference) do
        case to_data(reference) do
            { :ok, { type, attributes, data } } ->
                uri =
                    [
                        "data:",
                        type,
                        ";",
                        Enum.reduce(attributes, [], fn { k, v }, acc -> [[k, "=", v, ";"]|acc] end),
                        "base64,",
                        Base.encode64(data)
                    ]
                    |> IO.iodata_to_binary
                    |> URI.encode

                { :ok, uri }
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attributes(reference) do
        case to_data(reference) do
            { :ok, { _, attributes, _ } } -> { :ok, attributes }
            error -> error
        end
    end

    @doc """
      Manually create a data resource.

      Converts the static resource state or a binary into a data resource.

      The type defaults to an `"application/octet-stream"` or the parent type
      of the existing resource. This can be overridden by explicitly passing
      a type to the `:type` option.

      No attributes are attached to the data resource by default. This can be
      overridden by passing the attributes to the `:attributes` option.

        iex> { :ok, resource } = Resx.Producers.Data.new("hello")
        ...> resource.content
        %Resx.Resource.Content{ data: "hello", type: ["application/octet-stream"] }

        iex> { :ok, resource } = Resx.Producers.Data.new("hello", type: "text/plain")
        ...> resource.content.type
        ["text/plain"]

        iex> { :ok, resource } = Resx.Producers.Data.new("hello")
        ...> Resx.Resource.attribute(resource, "charset")
        { :error, { :unknown_key, "charset" } }

        iex> { :ok, resource } = Resx.Producers.Data.new("hello", attributes: %{ "charset" => "US-ASCII" })
        ...> Resx.Resource.attribute(resource, "charset")
        { :ok, "US-ASCII" }
    """
    @spec new(Resource.t | binary, [type: String.t, attributes: %{ optional(Resource.attribute_key) => any }]) :: { :ok, Resource.t } | Resx.error(Resx.resource_error | Resx.reference_error)
    def new(data, opts \\ [])
    def new(%Resource{ content: %{ type: type, data: data } }, opts) do
        type = case type do
            [type|_] -> type
            type -> type
        end

        { :ok, new(data, opts[:type] || type, opts[:attributes] || %{}) }
    end
    def new(data, opts), do: { :ok, new(data, opts[:type] || "application/octet-stream", opts[:attributes] || %{}) }

    @spec new(binary, String.t, %{ optional(Resource.attribute_key) => any }) :: Resource.t
    defp new(data, type, attributes) do
        content = %Content{
            type: case type do
                type when is_list(type) -> type
                type -> [type]
            end,
            data: data
        }
        %Resource{
            reference: %Reference{
                adapter: __MODULE__,
                repository: { type, attributes, data },
                integrity: %Integrity{
                    timestamp: DateTime.to_unix(DateTime.utc_now)
                }
            },
            content: content
        }
    end
end
