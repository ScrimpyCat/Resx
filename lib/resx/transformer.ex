defmodule Resx.Transformer do
    import Kernel, except: [apply: 2]

    alias Resx.Resource
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @callback transform(Resource.t) :: { :ok, resource :: Resource.t } | Resx.error

    defmodule TransformError do
        defexception [:message, :type, :reason]

        @impl Exception
        def exception({ type, reason }) do
            %TransformError{ message: "failed to transform resource due to #{type} error: #{inspect reason}", type: type, reason: reason }
        end
    end

    @doc """
      Apply a transformation to a resource.

      A `transformer` must be a module that implements the `Resx.Transformer`
      behaviour.
    """
    @spec apply(Resource.t, module) :: { :ok, Resource.t } | Resx.error
    def apply(resource, transformer) do
        case transformer.transform(resource) do
            { :ok, resource = %{ reference: reference } } ->
                { :ok, %{ resource | reference: %Reference{ adapter: Resx.Producers.Transform, repository: { transformer, reference }, integrity: %Integrity{ checksum: Resource.hash(resource), timestamp: DateTime.to_unix(DateTime.utc_now) } } } }
            { :error, error } -> { :error, error }
        end
    end

    def apply!(resource, transformer) do
        case apply(resource, transformer) do
            { :error, error } -> raise TransformError, error
            result -> result
        end
    end
end
