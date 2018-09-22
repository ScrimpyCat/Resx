defmodule Resx.Producer do
    alias Resx.Resource
    alias Resx.Resource.Reference

    @typedoc """
      Errors to do with the reference.

      * `:invalid_reference` - The reference structure is not valid. e.g.
      was malformed, reference of that structure is no longer supported,
      etc.
    """
    @type reference_error :: :invalid_reference

    @typedoc """
      Errors to do with the resource.

      * `:unknown_resource` - The resource does not exist
    """
    @type resource_error :: :unknown_resource

    @typedoc """
      An error.

      Any error type follows the format of `{ :error, { type, reason } }` where
      `type` is the type of error and `reason` is additional supporting details.

      * `:internal` - There was an internal error when handling the request. This
      is for errors that are not due to user input and don't belong to any of the
      other specified error types.
    """
    @type error(type) :: { :error, { :internal | type, reason :: term } }
    @type resource_attribute_key :: atom
    @type uri :: String.t
    @type ref :: uri | Reference.t

    @doc """
      Implement the behaviour for retrieving a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the resource was successfully retrieved return `{ :ok, resource }`. Where
      `resource` is the `Resx.Resource` struct. Otherwise return an appropriate
      error.
    """
    @callback open(ref) :: { :ok, resource :: Resource.t } | error(resource_error | reference_error)

    @doc """
      Implement the behaviour for checking whether a resource exists for the given
      reference.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the resource exists return `{ :ok, true }`, if it does not exist return
      `{ :ok, false }`. Otherwise return an appropriate error.
    """
    @callback exists?(ref) :: { :ok, exists :: boolean } | error(reference_error)

    @doc """
      Implement the behaviour for checking if two references point to the same
      resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the references are alike return `true`, otherwise return `false`.
    """
    @callback alike?(ref, ref) :: boolean

    @doc """
      Implement the behaviour to retrieve the URI for a resource reference.

      The reference to the resource is an existing `Resx.Resource.Reference`
      struct.

      If the URI can be created return `{ :ok, uri }`. Otherwise return an
      appropriate error.
    """
    @callback resource_uri(Reference.t) :: { :ok, uri } | error(resource_error | reference_error)

    @doc """
      Optionally implement the behaviour to retrieve the attribute for a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the attribute was successfully retrieved for the resource return
      `{ :ok, value }`, where `value` is the value of the attribute. Otherwise
      return an appropriate error.
    """
    @callback resource_attribute(ref, field :: resource_attribute_key) :: { :ok, attribute_value :: any } | error(resource_error | reference_error | :unknown_key)

    @callback resource_attributes(ref) :: { :ok, attribute_values :: %{ optional(resource_attribute_key) => any } } | error(resource_error | reference_error)

    @doc """
      Optionally implement the behaviour to retrieve the attribute keys for a resource.

      The reference to the resource can either be an existing `Resx.Resource.Reference`
      struct, or a URI.

      If the attribute was successfully retrieved for the resource return
      `{ :ok, keys }`, where `keys` are the field names of the different attributes.
      Otherwise return an appropriate error.
    """
    @callback resource_attribute_keys(ref) :: { :ok, [field :: resource_attribute_key] } | error(resource_error | reference_error)

    @doc false
    defmacro __using__(_opts) do
        quote do
            @behaviour Resx.Producer

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
                    { :ok, attributes } -> Map.keys(attributes)
                    error -> error
                end
            end

            defoverridable [resource_attribute: 2, resource_attribute_keys: 1]
        end
    end
end
