defmodule Resx.CallbackTest do
    use ExUnit.Case

    defmodule Foo do
        def bar(), do: {}

        def bar(a), do: { a }

        def bar(a, b), do: { a, b }

        def bar(a, b, c), do: { a, b, c }

        def bar(a, b, c, d), do: { a, b, c, d }
    end

    test "call with required inputs" do
        assert Exception.exception?(catch_error(Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil })))
        assert Exception.exception?(catch_error(Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [])))
        assert Exception.exception?(catch_error(Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [], :required)))
    end

    test "call/0" do
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 0 })
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] })
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 })
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] })
        assert {} == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/0)

        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 0 }, [])
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [])
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [])
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [])
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [], :optional)
        assert {} == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/0, [])
    end

    test "call/1" do
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 1 }, [:a])
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a] })
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a])
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], 0 })
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a])
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], [0, 2] })
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a])
        assert { :a } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/1, [:a])

        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], nil }, [], :optional)
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [:a], :optional)
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 1 }, [:a], :optional)
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a], :optional)
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a], :optional)
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a], :optional)
        assert { :a } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/1, [:a], :optional)
    end

    test "call/2" do
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 2 }, [:a, :b])
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b] })
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b])
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a] }, [:b])
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], 0 })
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b])
        assert { :b, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], 0 }, [:b])
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], [0, 2] })
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b])
        assert { :b, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], [0, 2] }, [:b])
        assert { :a, :b } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/2, [:a, :b])

        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], nil }, [], :optional)
        assert { :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], nil }, [:b], :optional)
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [:a, :b], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 2 }, [:a, :b], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a] }, [:b], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b], :optional)
        assert { :b, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], 0 }, [:b], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b], :optional)
        assert { :b, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], [0, 2] }, [:b], :optional)
        assert { :a, :b } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/2, [:a, :b], :optional)
    end

    test "call/3" do
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 3 }, [:a, :b, :c])
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c] })
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b, :c])
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b] }, [:c])
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a] }, [:b, :c])
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c], 0 })
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b, :c])
        assert { :c, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], 0 }, [:c])
        assert { :b, :c, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], 0 }, [:b, :c])
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c], [0, 2] })
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b, :c])
        assert { :c, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], [0, 2] }, [:c])
        assert { :b, :a, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], [0, 2] }, [:b, :c])
        assert { :a, :b, :c } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/3, [:a, :b, :c])

        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c], nil }, [], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], nil }, [:c], :optional)
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [:a, :b, :c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 3 }, [:a, :b, :c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b, :c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b] }, [:c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a] }, [:b, :c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b, :c], :optional)
        assert { :c, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], 0 }, [:c], :optional)
        assert { :b, :c, :a } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], 0 }, [:b, :c], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b, :c], :optional)
        assert { :c, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], [0, 2] }, [:c], :optional)
        assert { :b, :a, :c } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a], [0, 2] }, [:b, :c], :optional)
        assert { :a, :b, :c } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/3, [:a, :b, :c], :optional)
    end

    test "call/4" do
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 4 }, [:a, :b, :c, :d])
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c, :d] })
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b, :c, :d])
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b] }, [:c, :d])
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c, :d], 0 })
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b, :c, :d])
        assert { :c, :d, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], 0 }, [:c, :d])
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c, :d], [0, 2] })
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b, :c, :d])
        assert { :c, :a, :d, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], [0, 2] }, [:c, :d])
        assert { :a, :b, :c, :d } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/4, [:a, :b, :c, :d])

        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b, :c, :d], nil }, [], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], nil }, [:c, :d], :optional)
        assert {} == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], nil }, [:a, :b, :c, :d], :optional)
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, 4 }, [:a, :b, :c, :d], :optional)
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [] }, [:a, :b, :c, :d], :optional)
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b] }, [:c, :d], :optional)
        assert { :a, :b, :c, :d } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], 0 }, [:a, :b, :c, :d], :optional)
        assert { :c, :d, :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], 0 }, [:c, :d], :optional)
        assert { :a, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [], [0, 2] }, [:a, :b, :c, :d], :optional)
        assert { :c, :a, :d, :b } == Resx.Callback.call({ Resx.CallbackTest.Foo, :bar, [:a, :b], [0, 2] }, [:c, :d], :optional)
        assert { :a, :b, :c, :d } == Resx.Callback.call(&Resx.CallbackTest.Foo.bar/4, [:a, :b, :c, :d], :optional)
    end
end
