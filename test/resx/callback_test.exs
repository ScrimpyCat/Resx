defmodule Resx.CallbackTest do
    use ExUnit.Case

    defmodule Foo do
        def bar(), do: {}

        def bar(a), do: { a }

        def bar(a, b), do: { a, b }

        def bar(a, b, c), do: { a, b, c }

        def bar(a, b, c, d), do: { a, b, c, d }
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
    end
end
