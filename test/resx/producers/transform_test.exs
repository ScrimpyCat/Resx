defmodule Resx.Producers.TransformTest do
    use ExUnit.Case

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Transformer

    defmodule Prefixer do
        @behaviour Transformer

        @impl Transformer
        def transform(resource = %Resource{ content: content = %Content{} }, _) do
            { :ok, %{ resource | content: %{ content | data: "foo" <> content.data } } }
        end
        def transform(resource = %Resource{ content: content }, _) do
            { :ok, %{ resource | content: %{ content | data: Stream.concat(["foo"], content) } } }
        end
    end

    defmodule Suffixer do
        @behaviour Transformer

        @impl Transformer
        def transform(resource = %Resource{ content: content = %Content{} }, _) do
            { :ok, %{ resource | content: %{ content | data: content.data <> "bar" } } }
        end
        def transform(resource = %Resource{ content: content }, _) do
            { :ok, %{ resource | content: %{ content | data: Stream.concat(content, ["bar"]) } } }
        end
    end

    defmodule Replacer do
        @behaviour Transformer

        @impl Transformer
        def transform(resource = %Resource{ content: content }, options) do
            { :ok, %{ resource | content: %Content{ type: content.type, data: Content.data(content) |> String.replace(options[:pattern] || "", options[:replacement] || "") } } }
        end
    end

    describe "opening" do
        test "raw" do
            { :ok, original } = Resource.open("data:,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert "foofootestbar" == resource.content.data

            { :ok, uri } = Resource.uri(resource)
            { :ok, res } = Resource.open(uri)
            assert res.content == resource.content

            assert { :ok, resource_b } = Resource.open(resource)
            assert :lt == Resource.compare(resource, resource_b)
            assert resource.content == resource_b.content
            assert res.content == resource.content

            { :ok, resource } = Transformer.apply(resource, Replacer, pattern: "foo", replacement: "abc")
            assert "abcabctestbar" == resource.content.data
            { :ok, uri } = Resource.uri(resource)
            { :ok, res } = Resource.open(uri)
            assert res.content == resource.content
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert "foofooone two threebar" == Content.data(resource.content)

            { :ok, uri } = Resource.uri(resource)
            { :ok, res } = Resource.open(uri)
            assert res.content == Content.new(resource.content)

            assert { :ok, resource_b } = Resource.open(resource)
            assert :lt == Resource.compare(Resource.finalise!(resource), resource_b)
            assert resource.content != resource_b.content
            assert Content.new(resource.content) == resource_b.content
            assert res.content == Content.new(resource.content)

            { :ok, resource } = Transformer.apply(resource, Replacer, pattern: "foo", replacement: "abc")
            assert "abcabcone two threebar" == resource.content.data
            { :ok, uri } = Resource.uri(resource)
            { :ok, res } = Resource.open(uri)
            assert res.content == Content.new(resource.content)
        end
    end

    describe "uri" do
        test "raw" do
            { :ok, original } = Resource.open("data:,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            { :ok, original_uri } = Resource.uri(original)
            assert { :ok, "resx-transform:Resx.Producers.TransformTest.Suffixer,Resx.Producers.TransformTest.Prefixer,Resx.Producers.TransformTest.Prefixer,#{Base.encode64(original_uri)}" } == Resource.uri(resource)

            transform_options = [pattern: "foo", replacement: "abc"]
            { :ok, resource } = Transformer.apply(resource, Replacer, transform_options)
            assert { :ok, "resx-transform:Resx.Producers.TransformTest.Replacer:#{Base.encode64(:erlang.term_to_binary(transform_options))},Resx.Producers.TransformTest.Suffixer,Resx.Producers.TransformTest.Prefixer,Resx.Producers.TransformTest.Prefixer,#{Base.encode64(original_uri)}" } == Resource.uri(resource)
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            { :ok, original_uri } = Resource.uri(original)
            assert { :ok, "resx-transform:Resx.Producers.TransformTest.Suffixer,Resx.Producers.TransformTest.Prefixer,Resx.Producers.TransformTest.Prefixer,#{Base.encode64(original_uri)}" } == Resource.uri(resource)

            transform_options = [pattern: "foo", replacement: "abc"]
            { :ok, resource } = Transformer.apply(resource, Replacer, transform_options)
            assert { :ok, "resx-transform:Resx.Producers.TransformTest.Replacer:#{Base.encode64(:erlang.term_to_binary(transform_options))},Resx.Producers.TransformTest.Suffixer,Resx.Producers.TransformTest.Prefixer,Resx.Producers.TransformTest.Prefixer,#{Base.encode64(original_uri)}" } == Resource.uri(resource)
        end
    end

    describe "exists?" do
        test "raw" do
            { :ok, original } = Resource.open("data:,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, true } == Resource.exists?(resource)
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, true } == Resource.exists?(resource)
        end
    end

    describe "alike?" do
        test "raw" do
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

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert true == Resource.alike?(resource, resource)
            assert false == Resource.alike?(resource, original)

            { :ok, resource_b } = Transformer.apply(resource, Suffixer)

            assert false == Resource.alike?(resource, resource_b)

            { :ok, original } = Resource.open("data:,one%20two%20three")
            { :ok, resource_b } = Transformer.apply(original, Prefixer)
            { :ok, resource_b } = Transformer.apply(resource_b, Prefixer)
            { :ok, resource_b } = Transformer.apply(resource_b, Suffixer)

            assert true == Resource.alike?(resource, resource_b)

            { :ok, original } = Resource.open("data:,four%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource_b } = Transformer.apply(original, Prefixer)
            { :ok, resource_b } = Transformer.apply(resource_b, Prefixer)
            { :ok, resource_b } = Transformer.apply(resource_b, Suffixer)

            assert false == Resource.alike?(resource, resource_b)
        end
    end

    test "source/1" do
        { :ok, resource_a } = Resource.open("data:text/plain;foo=bar,test")
        { :ok, resource_b } = Transformer.apply(resource_a, Prefixer)
        { :ok, resource_c } = Transformer.apply(resource_b, Prefixer)
        { :ok, resource_d } = Transformer.apply(resource_c, Suffixer)

        assert { :ok, resource_c.reference } == Resource.source(resource_d)
        assert { :ok, resource_b.reference } == Resource.source(resource_c)
        assert { :ok, resource_a.reference } == Resource.source(resource_b)
        assert { :ok, nil } == Resource.source(resource_a)
    end

    describe "attributes" do
        test "raw" do
            { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, %{ "foo" => "bar" } } == Resource.attributes(resource)
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:text/plain;foo=bar,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, %{ "foo" => "bar" } } == Resource.attributes(resource)
        end
    end

    describe "attribute" do
        test "raw" do
            { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, "bar" } == Resource.attribute(resource, "foo")
            assert { :error, { :unknown_key, "bar" } } == Resource.attribute(resource, "bar")
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:text/plain;foo=bar,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, "bar" } == Resource.attribute(resource, "foo")
            assert { :error, { :unknown_key, "bar" } } == Resource.attribute(resource, "bar")
        end
    end

    describe "attribute keys" do
        test "raw" do
            { :ok, original } = Resource.open("data:text/plain;foo=bar,test")
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, ["foo"] } == Resource.attribute_keys(resource)
        end

        test "stream" do
            { :ok, original = %{ content: content } } = Resource.open("data:text/plain;foo=bar,one%20two%20three")
            original = %{ original | content: %Content.Stream{ type: content.type, data: String.split(content.data, ~r/ /, include_captures: true) } }
            { :ok, resource } = Transformer.apply(original, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Prefixer)
            { :ok, resource } = Transformer.apply(resource, Suffixer)

            assert { :ok, ["foo"] } == Resource.attribute_keys(resource)
        end
    end
end
