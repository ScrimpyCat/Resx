defmodule Resx do
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

      See `t:error/1` for more information.
    """
    @type error :: { :error, { :internal, reason :: term } }

    @typedoc """
      An error.

      Any error type follows the format of `{ :error, { type, reason } }` where
      `type` is the type of error and `reason` is additional supporting details.

      * `:internal` - There was an internal error when handling the request. This
      is for errors that are not due to user input and don't belong to any of the
      other specified error types.
    """
    @type error(type) :: { :error, { :internal | type, reason :: term } }
    @type uri :: String.t
    @type ref :: uri | Reference.t

    @default_producers %{
        "file" => Resx.Producers.File,
        "resx-transform" => Resx.Producers.Transform
    }

    def producer(%Resource{ reference: reference }), do: producer(reference)
    def producer(%Reference{ adapter: adapter }), do: adapter
    def producer(uri) do
        %{ scheme: scheme } = URI.parse(uri)

        Map.merge(@default_producers, Application.get_env(:resx, :producers, %{}))
        |> case do
            %{ ^scheme => adapter } -> adapter
            _ -> nil
        end
    end
end
