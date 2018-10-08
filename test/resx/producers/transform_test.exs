defmodule Resx.Producers.TransformTest do
    use ExUnit.Case

    alias Resx.Resource
    alias Resx.Transformer

    defmodule Prefixer do
        @behaviour Transformer

        @impl Transformer
        def transform(resource = %Resource{ content: content }) do
            { :ok, %{ resource | content: %{ content | data: "foo" <> content.data } } }
        end
    end

    defmodule Suffixer do
        @behaviour Transformer

        @impl Transformer
        def transform(resource = %Resource{ content: content }) do
            { :ok, %{ resource | content: %{ content | data: content.data <> "bar" } } }
        end
    end

    test "opening" do
        { :ok, original } = Resource.open("data:,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert "foofootestbar" == resource.content.data

        { :ok, uri } = Resource.uri(resource)
        { :ok, res } = Resource.open(uri)
        assert res.content == resource.content

        assert { :ok, ^resource } = Resource.open(resource)
        assert res.content == resource.content
    end

    test "uri" do
        { :ok, original } = Resource.open("data:,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        { :ok, original_uri } = Resource.uri(original)
        assert { :ok, "resx-transform:Resx.Producers.TransformTest.Suffixer,Resx.Producers.TransformTest.Prefixer,Resx.Producers.TransformTest.Prefixer,#{Base.encode64(original_uri)}" } == Resource.uri(resource)
    end

    test "exists?" do
        { :ok, original } = Resource.open("data:,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert { :ok, true } == Resource.exists?(resource)
    end

    test "alike?" do
        { :ok, original } = Resource.open("data:,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert true == Resource.alike?(resource, resource)
        assert false == Resource.alike?(resource, original)

        { :ok, resource_b } = Transformer.apply(resource, Suffixer)

        assert false == Resource.alike?(resource, resource_b)

        { :ok, original } = Resource.open("data:,tests")
        { :ok, resource_b } = Transformer.apply(original, Prefixer)
        { :ok, resource_b } = Transformer.apply(resource_b, Prefixer)
        { :ok, resource_b } = Transformer.apply(resource_b, Suffixer)

        assert false == Resource.alike?(resource, resource_b)
    end

    test "attributes" do
        { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert { :ok, %{ "foo" => "bar" } } == Resource.attributes(resource)
    end

    test "attribute" do
        { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert { :ok, "bar" } == Resource.attribute(resource, "foo")
        assert { :error, { :unknown_key, "bar" } } == Resource.attribute(resource, "bar")
    end

    test "attribute keys" do
        { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
        { :ok, resource } = Transformer.apply(original, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Prefixer)
        { :ok, resource } = Transformer.apply(resource, Suffixer)

        assert { :ok, ["foo"] } == Resource.attribute_keys(resource)
    end
end
