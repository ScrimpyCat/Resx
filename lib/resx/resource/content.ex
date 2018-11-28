defmodule Resx.Resource.Content do
    @moduledoc """
      The content of a resource.

        %Resx.Resource.Content{
            type: ["text/html]",
            data: "<p>Hello</p>"
        }
    """

    alias Resx.Resource.Content

    @enforce_keys [:type, :data]

    defstruct [:type, :data]

    @type acc :: any
    @type reducer :: (acc, (binary, acc -> acc) -> acc)
    @type mime :: String.t
    @type type :: [mime, ...]
    @type t :: %Content{
        type: type,
        data: any
    }

    @doc """
      Retrieve the content data.
    """
    @spec data(t | Content.Stream.t) :: any
    def data(%Content{ data: data }), do: data
    def data(%Content.Stream{ data: data }), do: Enum.join(data)

    @doc """
      Make some content explicit.
    """
    @spec new(t | Content.Stream.t) :: t
    def new(content), do: %Content{ type: content.type, data: data(content) }

    @doc """
      Get the binary reducer for this content.

      Returns a function that will reduce the content into its binary form.

      By default this returns a reducer that assumes content is already in its
      binary form. But this can be overridden by setting the `:content_reducer`
      to a function of type `(t | Content.Stream.t -> reducer)`. Valid function
      formats are any callback variant, see `Callback` for more information.

        config :resx,
            content_reducer: fn
                content = %{ type: ["x.native/erlang"|_] } -> &(&2.(:erlang.term_to_binary(Resx.Resource.Content.data(content)), &1))
                content -> &Enum.reduce(Resx.Resource.Content.Stream.new(content), &1, &2)
            end
    """
    @spec reducer(t | Content.Stream.t) :: reducer
    def reducer(content) do
        Application.get_env(:resx, :content_reducer, fn content ->
            &Enum.reduce(Content.Stream.new(content), &1, &2)
        end).(content)
    end
end
