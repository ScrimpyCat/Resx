defmodule Resx do
    @default_producers %{
        "file" => Resx.Producers.File
    }

    def producer_for_uri(uri) do
        %{ scheme: scheme } = URI.parse(uri)

        Map.merge(@default_producers, Application.get_env(:resx, :producers, %{}))
        |> case do
            %{ ^scheme => adapter } -> adapter
            _ -> nil
        end
    end
end
