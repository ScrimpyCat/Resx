defmodule Resx do
    alias Resx.Resource
    alias Resx.Resource.Reference

    @default_producers %{
        "file" => Resx.Producers.File
    }

    def producer(%Resource{ reference: reference }), do: producer(reference)
    def producer(%Reference{ adapter: adapter }), do: adapter
    def producer(uri) do
        %{ scheme: scheme } = URI.parse(uri)

        Map.merge(@default_producers, Application.get_env(:resx, :producers, %{}))
        |> case do
            %{ ^scheme => adapter } -> adapter
            _ -> nil
        end
    end
end
