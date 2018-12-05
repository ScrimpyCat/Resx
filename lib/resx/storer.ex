defmodule Resx.Storer do
    @moduledoc """
      A storer is an interface to perform some side-effect with a resource.

      While this is intended for things such as caching, or saving a resource at
      some destination. It may also be used for producing other side-effects such
      as logging, delivery/dispatch, etc.

      A store by itself is not referenceable, due to this it is suggested that the
      store should not modify the resource, as this is likely to lead to confusion
      when obtaining and passing around references. The suggested way of implementing
      a referenceable store, is to have the store implement the `Resx.Producer`
      behaviour as well. An example of this is the default file handler `Resx.Producers.File`,
      this is both a producer and a store.
    """
    alias Resx.Resource
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    @doc """
      Implement the behaviour to store a resource.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the transformation was successful return `{ :ok, resource }`, where `resource`
      is the newly transformed resource. Otherwise return an appropriate error.
    """
    @callback store(Resource.t, options :: keyword) :: { :ok, resource :: Resource.t } | Resx.error

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Storer
        end
    end

    defmodule StoreError do
        defexception [:message, :type, :reason, :storer, :resource]

        @impl Exception
        def exception({ resource, storer, options, { type, reason } }) do
            %StoreError{
                message: "failed to store resource due to #{type} error: #{inspect reason}",
                type: type,
                reason: reason,
                resource: resource,
                storer: storer,
                options: options
            }
        end
    end

    @doc """
      Save a resource in the target store.

      A `storer` must be a module that implements the `Resx.Storer`
      behaviour.
    """
    @spec save(Resource.t, module, keyword) :: { :ok, Resource.t } | Resx.error
    def save(resource, storer, opts \\ []), do: storer.store(resource, opts)

    @doc """
      Save a resource in the target store.

      Raises a `Resx.Storer.StoreError` if the resource couldn't be stored.

      For more details see `save/3`.
    """
    @spec save!(Resource.t, module, keyword) :: Resource.t | no_return
    def save!(resource, storer, opts \\ []) do
        case save(resource, storer, opts) do
            { :ok, resource } -> resource
            { :error, error } -> raise StoreError, { resource, storer, opts, error }
        end
    end
end
