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

    @type acc :: Enumerable.acc
    @type result :: Enumerable.result
    @type reducer(element) :: (acc, (element, acc -> acc) -> result)
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

        config :resx,
            content_combiner: fn
                %{ type: ["application/x.erlang.etf"|_], data: [data] } -> data
                content -> Content.Stream.combine(content, <<>>)
            end

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

      Returns an enumerable function that will reduce the content into the type
      requested.

      The default reducers for the different types are:

      * `:binary` - returns a reducer that assumes its content is already in binary
      form.

      Reducers can be overridden by setting the `:content_reducer` to a function
      of type `(t | Content.Stream.t, :binary | atom -> reducer)`. Valid function
      formats are any callback variant, see `Callback` for more information.

        config :resx,
            content_reducer: fn
                content = %{ type: ["application/x.erlang.etf"|_] }, :binary -> &Enumerable.reduce([:erlang.term_to_binary(Resx.Resource.Content.data(content))], &1, &2)
                content, :binary -> &Enumerable.reduce(Resx.Resource.Content.Stream.new(content), &1, &2)
            end

      The reducer should be able to be passed into an Enum or Stream function.

        iex> reduce = Resx.Resource.Content.reducer(%Resx.Resource.Content.Stream{ type: [], data: ["1", "2", "3"] })
        ...> reduce.({ :cont, "" }, &({ :cont, &2 <> &1 }))
        { :done, "123" }

        iex> reduce = Resx.Resource.Content.reducer(%Resx.Resource.Content.Stream{ type: [], data: ["1", "2", "3"] })
        ...> Enum.into(reduce, "")
        "123"

        iex> reduce = Resx.Resource.Content.reducer(%Resx.Resource.Content.Stream{ type: [], data: ["1", "2", "3"] })
        ...> Stream.take(reduce, 2) |> Enum.into("")
        "12"
    """
    @spec reducer(t | Content.Stream.t, :binary) :: reducer(binary)
    @spec reducer(t | Content.Stream.t, atom) :: reducer(term)
    def reducer(content, type \\ :binary)
    def reducer(content, type) do
        Application.get_env(:resx, :content_reducer, fn
            content, :binary -> &Enumerable.reduce(Content.Stream.new(content), &1, &2)
        end) |> Callback.call([content, type])
    end
end
