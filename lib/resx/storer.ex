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

    @doc """
      Implement the behaviour to store a resource.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the store was successful return `{ :ok, resource }`, where `resource` is the
      stored resource. Otherwise return an appropriate error.
    """
    @callback store(resource :: Resource.t, options :: keyword) :: { :ok, resource :: Resource.t } | Resx.error

    @doc """
      Optionally implement the behaviour to discard a resource. This should be used to
      reverse the effects of a store. The default implementation does nothing and just
      returns `:ok`.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the resource was successfully discarded return `:ok`. Otherwise return an
      appropriate error.
    """
    @callback discard(reference :: Resx.ref, options :: keyword) :: :ok | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc """
      Optionally implement this behaviour to indicate the source compatibility details
      of your producer/store implementation.

      Source compatibility is determined when storing a resource would result in
      the exact same resource as opening the resource with the other resource as
      its source. e.g. `store(a) == open(reference_with_source_a)`.

      By default an implementation of this function is provided that will return
      `:incompatible` if the implementation is not a producer, and `{ :compatible, :default }`
      if the implementation is a producer.

      The compatibility details that can be returned are:

      * `:incompatible` - The implementation does not provide source compatibility.
      * `{ :compatible, :default }` - The implementation does provide source
      compatibility, and the logic for dealing with sources is deferred to the
      standard `Resx.Resource` wrapper. In this situation your producer/store
      functions should only deal with accessing its own resource.
      * `{ :compatible, :internal }` - The implementation does provide source
      compatibility, and the logic for dealing with sources is handled internally.
      A reason you might want to handle it internally is if it can be done more
      efficiently that way.

      Return whether the implementation does provide a compatible source
      implementation or not.
    """
    @callback source_compatibility() :: :incompatible | { :compatible, :default | :internal }

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Storer
            @before_compile Resx.Storer

            @impl Resx.Storer
            def discard(_, _ \\ []), do: :ok

            defoverridable [discard: 1, discard: 2]
        end
    end

    defmodule StoreError do
        defexception [:message, :type, :reason, :storer, :resource, :options]

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

    defmacro __before_compile__(env) do
        if !Module.defines?(env.module, { :source_compatibility, 0 }, :def) do
            compatibility = if Resx.Producer in Module.get_attribute(env.module, :behaviour) do
                { :compatible, :default }
            else
                :incompatible
            end

            quote do
                @impl Resx.Storer
                def source_compatibility(), do: unquote(compatibility)
            end
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
