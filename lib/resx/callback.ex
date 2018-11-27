defmodule Resx.Callback do
    @typedoc """
      A module-function-arity tuple with an explicit arity.
    """
    @type mfa(arity) :: { module, atom, arity }

    @typedoc """
      A module-function-parameter tuple.

      This either contains a list of parameters that will be passed to the function,
      and any input parameters will be added following those parameters. Or an input
      index or list of indexes will be provided (in which case those inputs will be
      inserted into the parameter list at those positions). Or `nil` inputs, if no
      inputs should be included, this however is only applicable to calls where the
      input requirements `:optional`.

        { Foo, :bar, [:a, :b] }
        \# If the callback is not passing any inputs then this function will
        \# be called as:
        Foo.bar(:a, :b)
        \# If the callback is passing in 1 input ("hello"), then this function
        \# will be called as:
        Foo.bar(:a, :b, "hello")
        \# If the callback is passing in 2 inputs ("hello", "world"), then this
        \# function will be called as:
        Foo.bar(:a, :b, "hello", "world")

        { Foo, :bar, [:a, :b], 0 }
        \# If the callback is not passing any inputs then this function will
        \# be called as:
        Foo.bar(:a, :b)
        \# If the callback is passing in 1 input ("hello"), then this function
        \# will be called as:
        Foo.bar("hello", :a, :b)
        \# If the callback is passing in 2 inputs ("hello", "world"), then this
        \# function will be called as:
        Foo.bar("hello", "world", :a, :b)

        { Foo, :bar, [:a, :b], [0, 2] }
        \# If the callback is not passing any inputs then this function will
        \# be called as:
        Foo.bar(:a, :b)
        \# If the callback is passing in 1 input ("hello"), then this function
        \# will be called as:
        Foo.bar("hello", :a, :b)
        \# If the callback is passing in 2 inputs ("hello", "world"), then this
        \# function will be called as:
        Foo.bar("hello", :a, "world", :b)

        { Foo, :bar, [:a, :b], nil }
        \# If the callback is not passing any inputs then this function will
        \# be called as:
        Foo.bar(:a, :b)
        \# If the callback is passing in 1 input ("hello"), then this function
        \# will be called as:
        Foo.bar(:a, :b)
        \# If the callback is passing in 2 inputs ("hello", "world"), then this
        \# function will be called as:
        Foo.bar(:a, :b)
    """
    @type mfp :: { module, atom, list } | { module, atom, list, nil | non_neg_integer | [non_neg_integer] }

    @typedoc """
      A generic callback form with any amount of arguments.
    """
    @type callback :: fun | mfa | mfp

    @typedoc """
      An explicit callback form expecting 1 argument of the provided type, and
      returning a result of the provided type.
    """
    @type callback(arg1, result) :: (arg1 -> result) | mfa(1) | mfp

    @typedoc """
      An explicit callback form expecting 2 arguments of the provided type, and
      returning a result of the provided type.
    """
    @type callback(arg1, arg2, result) :: (arg1, arg2 -> result) | mfa(2) | mfp

    @doc """
      Returns `true` if `term` is a `callback`; otherwise returns `false`.

      Allowed in guard tests.
    """
    @spec is_callback(term) :: boolean
    defguard is_callback(callback)
        when is_tuple(callback)
            and ((tuple_size(callback) == 3 and is_atom(elem(callback, 0)) and is_atom(elem(callback, 1)) and (is_integer(elem(callback, 2)) or is_list(elem(callback, 2))))
            or (tuple_size(callback) == 4 and is_atom(elem(callback, 0)) and is_atom(elem(callback, 1)) and is_list(elem(callback, 2)) and (is_integer(elem(callback, 3)) or is_list(elem(callback, 3)) or is_nil(elem(callback, 3)))))
        or is_function(callback)

    @doc false
    @spec call(callback, list, :required | :optional) :: any
    def call(fun, inputs \\ [], input_requirement \\ :required)
    def call({ module, fun, args, nil }, _, :optional) do
        apply(module, fun, args)
    end
    def call({ module, fun, args, index }, inputs, _) when is_integer(index) do
        { left, right } = Enum.split(args, index)
        apply(module, fun, left ++ inputs ++ right)
    end
    def call({ module, fun, args, indexes }, inputs, _) do
        args = Enum.zip(indexes, inputs) |> Enum.sort |> insert_args(args)
        apply(module, fun, args)
    end
    def call({ module, fun, arity }, inputs, _) when is_integer(arity) and length(inputs) == arity do
        apply(module, fun, inputs)
    end
    def call({ module, fun, args }, inputs, _) when is_list(args) do
        apply(module, fun, args ++ inputs)
    end
    def call(fun, inputs, _) when is_function(fun, length(inputs)) do
        apply(fun, inputs)
    end

    defp insert_args(indexed, list, n \\ 0, result \\ [])
    defp insert_args([], [], _, args), do: Enum.reverse(args)
    defp insert_args([{ _, e }|indexed], [], n, args), do: insert_args(indexed, [], n + 1, [e|args])
    defp insert_args([{ n, e }|indexed], list, n, args), do: insert_args(indexed, list, n + 1, [e|args])
    defp insert_args(indexed, [e|list], n, args), do: insert_args(indexed, list, n + 1, [e|args])
end
