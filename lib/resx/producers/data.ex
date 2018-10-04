defmodule Resx.Producers.Data do
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
    def open(reference) do
        case to_data(reference) do
            { :ok, repo = { type, meta, data } } ->
                content = %Content{
                    type: type,
                    data: data
                }
                resource = %Resource{
                    reference: %Reference{
                        adapter: __MODULE__,
                        repository: repo,
                        integrity: %Integrity{
                            checksum: Resource.hash(content),
                            timestamp: DateTime.to_unix(DateTime.utc_now)
                        }
                    },
                    content: content
                }

                { :ok, resource }
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
                { :ok, data } = Base.encode64(data)

                Enum.map(attributes, fn { k, v } -> "#{k}=#{v}" end)
                |> Enum.join(";")
                |> case do
                    "" -> { :ok, URI.encode("data:#{type};base64,#{data}") }
                    params -> { :ok, URI.encode("data:#{type};#{params};base64,#{data}") }
                end
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
end
