defmodule Resx.Transformer do
    alias Resx.Resource
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @callback transform(Resource.t) :: { :ok, resource :: Resource.t } | Resx.error

    def apply(resource, transformer) do
        case transformer.transform(resource) do
            { :ok, resource = %{ reference: reference } } ->
                { :ok, %{ resource | reference: %Reference{ adapter: Resx.Producers.Transform, repository: { transformer, reference }, integrity: %Integrity{ checksum: Resource.hash(resource), timestamp: DateTime.to_unix(DateTime.utc_now) } } } }
            { :error, error } -> { :error, error }
        end
    end
end
