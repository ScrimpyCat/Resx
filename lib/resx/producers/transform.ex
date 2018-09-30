defmodule Resx.Producers.Transform do
    use Resx.Producer

    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

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
    defp build_ref([module|modules], base) do
        build_ref(modules, %Reference{
            adapter: __MODULE__,
            repository: base,
            integrity: nil
        })
    end

    defp get_stages(path, modules \\ [])
    defp get_stages([], _), do: "missing transformation"
    defp get_stages([_], []), do: "missing transformation"
    defp get_stages([data], modules), do: { modules, Base.decode64(data) }
    defp get_stages([module|path], modules) do
        try do
            Module.safe_concat([module])
        rescue
            _ -> "transformation (#{module}) does not exist"
        else
            module -> get_stages(path, [module|modules])
        end
    end
end
