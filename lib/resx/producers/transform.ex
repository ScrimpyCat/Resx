defmodule Resx.Producers.Transform do
    use Resx.Producer

    alias Resx.Resource
    alias Resx.Resource.Reference

    defp to_ref(reference = %Reference{}), do: { :ok, reference }
    defp to_ref(uri) when is_binary(uri), do: URI.decode(uri) |> URI.parse |> to_ref
    defp to_ref(%URI{ scheme: "resx-transform", path: path }) do
        String.split(path, ",", trim: true)
        |> get_stages
        |> case do
            { modules = [_|_], { :ok, uri } } -> build_ref(modules, uri)
            { _, _ } -> { :error, { :invalid_reference, "data is not base64" } }
            reason -> { :error, { :invalid_reference, reason } }
        end
        |> to_ref
    end
    defp to_ref(error = { :error, _ }), do: error
    defp to_ref(_), do: { :error, { :invalid_reference, "not a transformation reference" } }

    defp build_ref([], base), do: base
    defp build_ref([{ module, options }|modules], base) do
        build_ref(modules, %Reference{
            adapter: __MODULE__,
            repository: { module, options, base },
            integrity: nil
        })
    end

    defp get_stages(path, modules \\ [])
    defp get_stages([], _), do: "missing transformation"
    defp get_stages([_], []), do: "missing transformation"
    defp get_stages([data], modules), do: { modules, Base.decode64(data) }
    defp get_stages([module|path], modules) do
        { module, options } = case String.split(module, ":") do
            [module] -> { module, [] }
            [module, options] ->
                options = case Base.decode64(options) do
                    { :ok, options } ->
                        try do
                            :erlang.binary_to_term(options)
                        rescue
                            _ -> "invalid transformation option"
                        end
                    _ -> "transformation option is not base64"
                end
                { module, options }
        end

        try do
            Module.safe_concat([module])
        rescue
            _ -> "transformation (#{module}) does not exist"
        else
            module -> get_stages(path, [{ module, options }|modules])
        end
    end

    @impl Resx.Producer
    def schemes(), do: ["resx-transform"]

    @impl Resx.Producer
    def open(reference, opts \\ []) do
        case to_ref(reference) do
            { :ok, %Reference{ repository: { transformer, options, reference } } } ->
                case Resource.open(reference, opts) do
                    { :ok, resource } -> Resx.Transformer.apply(resource, transformer, options)
                    error -> error
                end
            error -> error
        end
    end

    @impl Resx.Producer
    def exists?(reference) do
        case to_ref(reference) do
            { :ok, %Reference{ repository: { _, _, reference } } } -> Resource.exists?(reference)
            error -> error
        end
    end

    @impl Resx.Producer
    def alike?(a, b) do
        with { :a, { :ok, %Reference{ repository: { transformer, options, reference_a } } } } <- { :a, to_ref(a) },
             { :b, { :ok, %Reference{ repository: { ^transformer, ^options, reference_b } } } } <- { :b, to_ref(b) } do
                Resource.alike?(reference_a, reference_b)
        else
            _ -> false
        end
    end

    defp format_options([]), do: []
    defp format_options(options), do: [":", :erlang.term_to_binary(options) |> Base.encode64]

    defp to_uri(reference, transformations \\ [])
    defp to_uri(%Reference{ repository: { transformer, options, reference = %Reference{ adapter: __MODULE__ } } }, transformations), do: to_uri(reference, [transformations, [[inspect(transformer)|format_options(options)], ","]])
    defp to_uri(%Reference{ repository: { transformer, options, reference } }, transformations) do
        case Resource.uri(reference) do
            { :ok, uri } ->
                uri =
                    [
                        "resx-transform:",
                        transformations,
                        [inspect(transformer)|format_options(options)],
                        ",",
                        Base.encode64(uri)
                    ]
                    |> IO.iodata_to_binary
                    |> URI.encode

                { :ok, uri }
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_uri(reference) do
        case to_ref(reference) do
            { :ok, reference } -> to_uri(reference)
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attribute(reference, field) do
        case to_ref(reference) do
            { :ok, %Reference{ repository: { _, _, reference } } } -> Resource.attribute(reference, field)
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attributes(reference) do
        case to_ref(reference) do
            { :ok, %Reference{ repository: { _, _, reference } } } -> Resource.attributes(reference)
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attribute_keys(reference) do
        case to_ref(reference) do
            { :ok, %Reference{ repository: { _, _, reference } } } -> Resource.attribute_keys(reference)
            error -> error
        end
    end
end
