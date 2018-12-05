defmodule Resx.Transformer do
    @moduledoc """
      A transformer is a referencable interface for performing reproducible
      modifications on resources.

      A module that implements the transformer behaviour becomes usable by the
      `Resx.Producers.Transform` producer.
    """
    import Kernel, except: [apply: 2]

    alias Resx.Resource
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @doc """
      Implement the behaviour to transform a resource.

      If the transformation was successful return `{ :ok, resource }`, where `resource`
      is the newly transformed resource. Otherwise return an appropriate error.
    """
    @callback transform(reference :: Resource.t) :: { :ok, resource :: Resource.t } | Resx.error

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Transformer
        end
    end

    defmodule TransformError do
        defexception [:message, :type, :reason, :transformer, :resource]

        @impl Exception
        def exception({ resource, transformer, { type, reason } }) do
            %TransformError{
                message: "failed to transform resource due to #{type} error: #{inspect reason}",
                type: type,
                reason: reason,
                resource: resource,
                transformer: transformer
            }
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
                { :ok, %{ resource | reference: %Reference{ adapter: Resx.Producers.Transform, repository: { transformer, reference }, integrity: %Integrity{ timestamp: DateTime.to_unix(DateTime.utc_now) } } } }
            { :error, error } -> { :error, error }
        end
    end

    @doc """
      Apply a transformation to a resource.

      Raises a `Resx.Transformer.TransformError` if the transformation cannot be applied.

      For more details see `apply/2`.
    """
    @spec apply!(Resource.t, module) :: Resource.t | no_return
    def apply!(resource, transformer) do
        case apply(resource, transformer) do
            { :ok, resource } -> resource
            { :error, error } -> raise TransformError, { resource, transformer, error }
        end
    end
end
