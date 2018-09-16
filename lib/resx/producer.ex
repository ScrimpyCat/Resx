defmodule Resx.Producer do
    alias Resx.Resource

    @type error(type) :: { :error, { :internal | type, reason :: term } }
    @type resource_error :: :unknown_resource | :malformed_resource
    @type resource_attribute_key :: atom

    @callback resource_uri(resource :: Resource.t) :: { :ok, result :: any } | error(resource_error)

    @callback get_resource_attribute(resource :: Resource.t, field :: resource_attribute_key) :: { :ok, result :: any } | error(resource_error | :unknown_key)

    @callback get_resource_attributes(resource :: Resource.t) :: { :ok, result :: %{ optional(resource_attribute_key) => any } } | error(resource_error)

    @callback resource_attributes(resource :: Resource.t) :: { :ok, [field :: resource_attribute_key] } | error(resource_error)
end
