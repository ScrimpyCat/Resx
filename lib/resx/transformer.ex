defmodule Resx.Transformer do
    @moduledoc """
      A transformer is a referenceable interface for performing reproducible
      modifications on resources.

      A module that implements the transformer behaviour becomes usable by the
      `Resx.Producers.Transform` producer.
    """
    import Kernel, except: [apply: 3]

    alias Resx.Resource
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @doc """
      Implement the behaviour to transform a resource.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the transformation was successful return `{ :ok, resource }`, where `resource`
      is the newly transformed resource. Otherwise return an appropriate error.
    """
    @callback transform(resource :: Resource.t, options :: keyword) :: { :ok, resource :: Resource.t } | Resx.error

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Transformer
        end
    end

    defmodule TransformError do
        defexception [:message, :type, :reason, :transformer, :resource, :options]

        @impl Exception
        def exception({ resource, transformer, options, { type, reason } }) do
            %TransformError{
                message: "failed to transform resource due to #{type} error: #{inspect reason}",
                type: type,
                reason: reason,
                resource: resource,
                transformer: transformer,
                options: options
            }
        end
    end

    @doc """
      Apply a transformation to a resource.

      A `transformer` must be a module that implements the `Resx.Transformer`
      behaviour.
    """
    @spec apply(Resource.t, module, keyword) :: { :ok, Resource.t } | Resx.error
    def apply(resource, transformer, opts \\ []) do
        case transformer.transform(resource, opts) do
            { :ok, resource = %{ reference: reference } } ->
                { :ok, %{ resource | reference: %Reference{ adapter: Resx.Producers.Transform, repository: { transformer, opts, reference }, integrity: %Integrity{ timestamp: DateTime.utc_now } } } }
            { :error, error } -> { :error, error }
        end
    end

    @doc """
      Apply a transformation to a resource.

      Raises a `Resx.Transformer.TransformError` if the transformation cannot be applied.

      For more details see `apply/2`.
    """
    @spec apply!(Resource.t, module, keyword) :: Resource.t | no_return
    def apply!(resource, transformer, opts \\ []) do
        case apply(resource, transformer, opts) do
            { :ok, resource } -> resource
            { :error, error } -> raise TransformError, { resource, transformer, opts, error }
        end
    end
end
