defmodule Resx.Producer do
    alias Resx.Resource
    alias Resx.Resource.Reference

    @type error(type) :: { :error, { :internal | type, reason :: term } }
    @type reference_error :: :invalid_reference
    @type resource_error :: :unknown_resource
    @type resource_attribute_key :: atom
    @type uri :: String.t
    @type ref :: uri | Reference.t

    @callback open(ref) :: { :ok, resource :: Resource.t } | error(resource_error | reference_error)

    @callback exists?(ref) :: { :ok, exists :: boolean } | error(reference_error)

    @callback resource_uri(Reference.t) :: { :ok, uri } | error(resource_error | reference_error)

    @callback get_resource_attribute(ref, field :: resource_attribute_key) :: { :ok, attribute_value :: any } | error(resource_error | reference_error | :unknown_key)

    @callback get_resource_attributes(ref) :: { :ok, attribute_values :: %{ optional(resource_attribute_key) => any } } | error(resource_error | reference_error)

    @callback resource_attributes(ref) :: { :ok, [field :: resource_attribute_key] } | error(resource_error | reference_error)
end
