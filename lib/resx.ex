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

    @default_producers Utility.map_schemes(%{}, [
        Resx.Producers.Data,
        Resx.Producers.File,
        Resx.Producers.Transform
    ])

    @doc """
      Get the producer module for the given URI scheme.

      By default the following URI schemes will be matched to these producers:

       Scheme | Producer
      --------|----------
      #{Enum.map(@default_producers, fn { k, v } -> "__#{k}__|`#{inspect v}`" end) |> Enum.join("\n")}

      Custom mappings can be provided (or overridden) by configuring the `:producers`
      key.

        config :resx,
            producers: [
                MyDataProducer, \# Add any scheme configuration from MyDataProducer
                { "file", nil }, \# Overrides the default file scheme to have no producer
                { "custom", MyDataProducer } \# Map a new URI scheme to MyDataProducer
            ]
    """
    @spec producer(ref | Resource.t) :: module | nil
    def producer(%Resource{ reference: reference }), do: producer(reference)
    def producer(%Reference{ adapter: adapter }), do: adapter
    def producer(uri) do
        %{ scheme: scheme } = URI.parse(uri)

        Utility.map_schemes(@default_producers, Application.get_env(:resx, :producers, []))
        |> case do
            %{ ^scheme => adapter } -> adapter
            _ -> nil
        end
    end

    @doc """
      Shorthand for obtaining the reference.
    """
    @spec ref(ref | Resource.t) :: ref
    def ref(%Resource{ reference: reference }), do: reference
    def ref(reference), do: reference
end
