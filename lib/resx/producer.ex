defmodule Resx.Producer do
    alias Resx.Resource
    alias Resx.Resource.Reference

    @type error(type) :: { :error, { :internal | type, reason :: term } }
    @type resource_error :: :unknown_resource | :malformed_resource
    @type resource_attribute_key :: atom
    @type uri :: String.t

    @callback open(uri) :: { :ok, resource :: Resource.t } | error(resource_error)

    @callback resource_uri(reference :: Reference.t) :: { :ok, result :: uri } | error(resource_error)

    @callback get_resource_attribute(reference :: Reference.t, field :: resource_attribute_key) :: { :ok, result :: any } | error(resource_error | :unknown_key)

    @callback get_resource_attributes(reference :: Reference.t) :: { :ok, result :: %{ optional(resource_attribute_key) => any } } | error(resource_error)

    @callback resource_attributes(reference :: Reference.t) :: { :ok, [field :: resource_attribute_key] } | error(resource_error)
end
