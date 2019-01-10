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
    @type reducer(type) :: (acc, (type, acc -> acc) -> acc)
    @type mime :: String.t
    @type type :: [mime, ...]
    @type t :: %Content{
        type: type,
        data: any
    }

    @doc """
      Retrieve the content data.

      By default content stream's will be concatenated into a single binary if
      all parts are binaries, otherwise it will return a list of the unmodified
      parts. This behaviour can be overridden by setting the `:content_combiner`
      to a function of type `(Content.Stream.t -> any)`. Valid function formats
      are any callback variant, see `Callback` for more information.

      To still use the default combiner in your custom combiner, you can pass the
      content to `Resx.Resource.Content.Stream.combine(content, <<>>)`.

        iex> Resx.Resource.Content.data(%Resx.Resource.Content{ type: [], data: "foo" })
        "foo"

        iex> Resx.Resource.Content.data(%Resx.Resource.Content.Stream{ type: [], data: ["foo", "bar"] })
        "foobar"

        iex> Resx.Resource.Content.data(%Resx.Resource.Content.Stream{ type: [], data: ["foo", :bar] })
        ["foo", :bar]
    """
    @spec data(t | Content.Stream.t) :: any
    def data(content = %Content.Stream{}) do
        Application.get_env(:resx, :content_combiner, &Content.Stream.combine(&1, <<>>))
        |> Callback.call([content])
    end
    def data(content), do: content.data

    @doc """
      Make some content explicit.
    """
    @spec new(t | Content.Stream.t) :: t
    def new(content), do: %Content{ type: content.type, data: data(content) }

    @doc """
      Get the reducer for this content.

      Returns a function that will reduce the content into the type requested.

      The default reducers for the different types are:

      * `:binary` - returns a reducer that assumes its content is already in binary
      form.

      Reducers can be overridden by setting the `:content_reducer` to a function
      of type `(t | Content.Stream.t, :binary | atom -> reducer)`. Valid function
      formats are any callback variant, see `Callback` for more information.

        config :resx,
            content_reducer: fn
                content = %{ type: ["x.native/erlang"|_] }, :binary -> &(&2.(:erlang.term_to_binary(Resx.Resource.Content.data(content)), &1))
                content, :binary -> &Enum.reduce(Resx.Resource.Content.Stream.new(content), &1, &2)
            end
    """
    @spec reducer(t | Content.Stream.t, :binary) :: reducer(binary)
    @spec reducer(t | Content.Stream.t, atom) :: reducer(term)
    def reducer(content, type \\ :binary)
    def reducer(content, type) do
        Application.get_env(:resx, :content_reducer, fn
            content, :binary -> &Enum.reduce(Content.Stream.new(content), &1, &2)
        end) |> Callback.call([content, type])
    end
end
