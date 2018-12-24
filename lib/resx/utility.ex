defmodule Utility do
    @moduledoc false

    @doc false
    @spec map_schemes(%{ optional(String.t) => module }, [module | { String.t, module }]) :: %{ optional(String.t) => module }
    def map_schemes(map \\ %{}, producers)
    def map_schemes(map, []), do: map
    def map_schemes(map, [{ scheme, producer }|producers]), do: Map.put(map, scheme, producer) |> map_schemes(producers)
    def map_schemes(map, [producer|producers]), do: Map.merge(map, Map.new(Enum.map(producer.schemes, &({ &1, producer })))) |> map_schemes(producers)
end
