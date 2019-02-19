defmodule Resx.ResourceTest do
    use ExUnit.Case
    doctest Resx.Resource

    alias Resx.Resource

    defmodule Nothing do
        use Resx.Transformer

        def transform(resource, opts), do: { :ok, resource }
    end

    test "comparison" do
        a = Resource.open!("data:,hello") |> Resource.finalise!

        assert nil == Resource.compare(a, Resource.open!("data:,foo"))
        assert nil == Resource.compare(a, Resource.open!("data:;foo=foo,hello"))

        assert :eq == Resource.compare(a, a)
        assert :na == Resource.compare(a, %{ a | reference: %{ a.reference | integrity: %{ a.reference.integrity | checksum: nil } } })
        assert :eq == Resource.compare(a, %{ a | reference: %{ a.reference | integrity: %{ a.reference.integrity | checksum: nil } } }, content: true)
        assert :ne == Resource.compare(a, %{ a | reference: %{ a.reference | integrity: %{ a.reference.integrity | checksum: nil } } }, unsure: :ne)
        assert :eq == Resource.compare(a, %{ a | content: %{ a.content | data: "test" } })
        assert :ne == Resource.compare(a, %{ a | content: %{ a.content | data: "test" } }, content: true)

        b = Resource.open!("data:,hello") |> Resource.finalise!

        assert :lt == Resource.compare(a, b)
        assert :lt == Resource.compare(a, b, order: :first)
        assert :lt == Resource.compare(a, b, order: :last)
        assert :lt == Resource.compare(a, b, content: true)
        assert :gt == Resource.compare(b, a)
        assert :gt == Resource.compare(b, a, order: :first)
        assert :gt == Resource.compare(b, a, order: :last)
        assert :gt == Resource.compare(b, a, content: true)

        b = Resource.transform!(b, Nothing)
        a = Resource.transform!(a, Nothing)

        assert :lt == Resource.compare(a, b)
        assert :lt == Resource.compare(a, b, order: :first)
        assert :gt == Resource.compare(a, b, order: :last)
        assert :lt == Resource.compare(a, b, content: true)
        assert :gt == Resource.compare(b, a)
        assert :gt == Resource.compare(b, a, order: :first)
        assert :lt == Resource.compare(b, a, order: :last)
        assert :gt == Resource.compare(b, a, content: true)

        assert :na == Resource.compare(a, a)
        assert :na == Resource.compare(a, a, order: :first)
        assert :eq == Resource.compare(a, a, order: :last)
        assert :eq == Resource.compare(a, a, content: true)

        a = Resource.open!("data:,hello")
        a = Resource.transform!(a, Nothing)
        b = a

        assert :na == Resource.compare(a, b)
        assert :na == Resource.compare(a, b, order: :first)
        assert :na == Resource.compare(a, b, order: :last)
        assert :eq == Resource.compare(a, b, content: true)
        assert :na == Resource.compare(b, a)
        assert :na == Resource.compare(b, a, order: :first)
        assert :na == Resource.compare(b, a, order: :last)
        assert :eq == Resource.compare(b, a, content: true)

        a = Resource.finalise!(a)
        b = Resource.finalise!(b)

        assert :eq == Resource.compare(a, b)
        assert :eq == Resource.compare(a, b, order: :first)
        assert :na == Resource.compare(a, b, order: :last)
        assert :eq == Resource.compare(a, b, content: true)
        assert :eq == Resource.compare(b, a)
        assert :eq == Resource.compare(b, a, order: :first)
        assert :na == Resource.compare(b, a, order: :last)
        assert :eq == Resource.compare(b, a, content: true)
    end
end
