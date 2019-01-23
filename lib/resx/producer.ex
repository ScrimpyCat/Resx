defmodule Resx.Producer do
    @moduledoc """
      A producer is an interface for working with a referenceable resource.

      This could be anything from a type of storage or networking protocol, to
      generation of content (e.g. you might expose some procedural generation
      algorithm as a producer), to manipulations on other resources (there is
      already a common way to handle this through `Resx.Transformer`).
    """
    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference

    @doc """
      Implement the behaviour for retrieving the URI schemes this producer can
      handle.

      Return a list of the scheme names.
    """
    @callback schemes() :: [String.t, ...]

    @doc """
      Implement the behaviour for retrieving a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the resource was successfully retrieved return `{ :ok, resource }`. Where
      `resource` is the `Resx.Resource` struct. Otherwise return an appropriate
      error.
    """
    @callback open(reference :: Resx.ref, options :: keyword) :: { :ok, resource :: Resource.t(Content.t) } | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc """
      Optionally implement the behaviour for retrieving a resource stream.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      The `options` keyword allows for your implementation to expose some configurable
      settings.

      If the resource was successfully retrieved return `{ :ok, resource }`. Where
      `resource` is the `Resx.Resource` struct. Otherwise return an appropriate
      error.
    """
    @callback stream(reference :: Resx.ref, options :: keyword) :: { :ok, resource :: Resource.t(Content.Stream.t) } | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc """
      Implement the behaviour for checking whether a resource exists for the given
      reference.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the resource exists return `{ :ok, true }`, if it does not exist return
      `{ :ok, false }`. Otherwise return an appropriate error.
    """
    @callback exists?(reference :: Resx.ref) :: { :ok, exists :: boolean } | Resx.error(Resx.reference_error)

    @doc """
      Implement the behaviour for checking if two references point to the same
      resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the references are alike return `true`, otherwise return `false`.
    """
    @callback alike?(reference_a :: Resx.ref, reference_b :: Resx.ref) :: boolean

    @doc """
      Implement the behaviour to retrieve source (if any).

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the source can be retrieved return `{ :ok, source }`, where `source` is
      either the reference chain for the source or `nil` if there is none. Otherwise
      return an appropriate error.
    """
    @callback source(reference :: Resx.ref) :: { :ok, source :: Resx.ref | nil } | Resx.error(Resx.reference_error)

    @doc """
      Implement the behaviour to retrieve the URI for a resource reference.

      The reference to the resource is an existing `Resx.Resource.Reference`
      struct.

      If the URI can be created return `{ :ok, uri }`. Otherwise return an
      appropriate error.
    """
    @callback resource_uri(reference :: Reference.t) :: { :ok, Resx.uri } | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc """
      Optionally implement the behaviour to retrieve the attribute for a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the attribute was successfully retrieved for the resource return
      `{ :ok, value }`, where `value` is the value of the attribute. Otherwise
      return an appropriate error.
    """
    @callback resource_attribute(reference :: Resx.ref, field :: Resource.attribute_key) :: { :ok, attribute_value :: any } | Resx.error(Resx.resource_error | Resx.reference_error | :unknown_key)

    @doc """
      Implement the behaviour to retrieve the attributes for a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the attributes were successfully retrieved for the resource return
      `{ :ok, %{ key => value } }`, where `key` is the field names of the attribute,
      and `value` is the value of the attribute. Otherwise return an appropriate error.
    """
    @callback resource_attributes(reference :: Resx.ref) :: { :ok, attribute_values :: %{ optional(Resource.attribute_key) => any } } | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc """
      Optionally implement the behaviour to retrieve the attribute keys for a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the attribute was successfully retrieved for the resource return
      `{ :ok, keys }`, where `keys` are the field names of the different attributes.
      Otherwise return an appropriate error.
    """
    @callback resource_attribute_keys(reference :: Resx.ref) :: { :ok, [field :: Resource.attribute_key] } | Resx.error(Resx.resource_error | Resx.reference_error)

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Producer

            @impl Resx.Producer
            def stream(reference, opts \\ []) do
                case __MODULE__.open(reference, opts) do
                    { :ok, resource = %Resource{ content: content } } -> { :ok, %{ resource | content: Content.Stream.new(content) } }
                    error -> error
                end
            end

            @impl Resx.Producer
            def resource_attribute(reference, field) do
                case __MODULE__.resource_attributes(reference) do
                    { :ok, attributes } ->
                        if Map.has_key?(attributes, field) do
                            { :ok, attributes[field] }
                        else
                            { :error, { :unknown_key, field } }
                        end
                    error -> error
                end
            end

            @impl Resx.Producer
            def resource_attribute_keys(reference) do
                case __MODULE__.resource_attributes(reference) do
                    { :ok, attributes } -> { :ok, Map.keys(attributes) }
                    error -> error
                end
            end

            defoverridable [stream: 1, stream: 2, resource_attribute: 2, resource_attribute_keys: 1]
        end
    end
end
