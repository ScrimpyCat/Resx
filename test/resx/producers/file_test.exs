defmodule Resx.Producers.FileTest do
    use ExUnit.Case
    doctest Resx.Producers.File

    alias Resx.Resource
    alias Resx.Resource.Content

    describe "open/1" do
        test "no access" do
            Application.put_env(:resx, Resx.Producers.File, access: [])
            assert { :error, { :invalid_reference, "protected file" } } == Resource.open("file://#{__DIR__}/file_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resource.open("file://localhost#{__DIR__}/file_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resource.open("file://#{node()}#{__DIR__}/file_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resource.open("file://foo@bar#{__DIR__}/transform_test.exs")
        end

        test "glob access paths" do
            Application.put_env(:resx, Resx.Producers.File, access: [
                "/path/to/foo.txt",
                "**/bar.txt",
                "**/all/**",
                "**/some/*",
                "/foo.{txt,jpg}",
                "/foo-?.txt",
                "/foo_[01].txt",
                "/bar_[!01].txt",
                "/bar-[0-9a-z].txt",
                "/baz-[!0-9a-z].txt"
            ])

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///anotherpath/to/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///all/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///all/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/all/other/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///some/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///some/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/some/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/to/some/other/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.jpg")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo.txts")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo-1.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo-n.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo-12.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo_0.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo_1.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo_2.txt")

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar_0.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar_1.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar_2.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-0.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-7.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-a.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-n.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-z.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar-A.txt")

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-0.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-7.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-a.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-n.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-z.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///baz-A.txt")

            Application.put_env(:resx, Resx.Producers.File, access: ["**"])
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")

            Application.put_env(:resx, Resx.Producers.File, access: ["/*"])
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/to/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")
        end

        test "regex access paths" do
            Application.put_env(:resx, Resx.Producers.File, access: [
                ~r/^\/path\/to\/foo\.txt$/,
                ~r/\/bar\.txt$/,
                ~r/\/all\//,
                ~r/\/some\/[^\/]*$/,
                ~r/^\/foo\.(txt|jpg)$/,
                ~r/^\/foo-.\.txt$/,
                ~r/^\/foo_[01]\.txt$/,
                ~r/^\/bar_[^01]\.txt$/,
                ~r/^\/bar-[0-9a-z]\.txt$/,
                ~r/^\/baz-[^0-9a-z]\.txt$/
            ])

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///anotherpath/to/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///all/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///all/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/all/other/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///some/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///some/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/some/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/to/some/other/foo.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.jpg")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo.txts")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo-1.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo-n.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo-12.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo_0.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo_1.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo_2.txt")

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar_0.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar_1.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar_2.txt")

            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-0.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-7.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-a.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-n.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar-z.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///bar-A.txt")

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-0.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-7.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-a.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-n.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///baz-z.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///baz-A.txt")

            Application.put_env(:resx, Resx.Producers.File, access: [~r/.*/])
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/to/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///path/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")

            Application.put_env(:resx, Resx.Producers.File, access: [~r/^\/[^\/]*$/])
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/to/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")
        end

        test "callback access paths" do
            Application.put_env(:resx, Resx.Producers.File, access: [&(&1 == "/foo.txt")])
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/to/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///path/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///foo.txt")
        end

        test "node paths" do
            Application.put_env(:resx, Resx.Producers.File, access: [
                { :foo@bar, "/foo.txt" },
                { node(), "/bar.txt" },
                { &(&1 in [:a@a, :a@b]), "/baz.txt" }
            ])

            assert { :error, { :invalid_reference, _ } } = Resource.open("file:///foo.txt")
            assert { :error, { :internal, { :badrpc, :nodedown } } } = Resource.open("file://foo@bar/foo.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file:///bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file://localhost/bar.txt")
            assert { :error, { :unknown_resource, _ } } = Resource.open("file://#{node()}/bar.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file://foo@bar/bar.txt")
            assert { :error, { :internal, { :badrpc, :nodedown } } } = Resource.open("file://a@a/baz.txt")
            assert { :error, { :internal, { :badrpc, :nodedown } } } = Resource.open("file://a@b/baz.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file://a@a/foo.txt")
            assert { :error, { :invalid_reference, _ } } = Resource.open("file://a@a/foo.txt")
        end

        test "content" do
            Application.put_env(:resx, Resx.Producers.File, access: ["**"])
            assert { :ok, %Resource{ content: %Content{ type: ["application/octet-stream"], data: "defmodule Resx.Producers.FileTest do" <> _ } } } = Resource.open("file://#{__DIR__}/file_test.exs")
        end

        test "distributed" do
            { :ok, _ } = LocalCluster.start()

            [node_a, node_b] = LocalCluster.start_nodes("test", 2)

            :rpc.call(node_a, Application, :put_env, [:resx, Resx.Producers.File, [access: ["**/test/resx/producers/file_test.exs", { node(), "**/test/resx/producers/transform_test.exs" }]]])
            :rpc.call(node_b, Application, :put_env, [:resx, Resx.Producers.File, [access: ["**/test/resx/producers/data_test.exs", { node(), "**" }, { node_a, "**" }]]])
            Application.put_env(:resx, Resx.Producers.File, access: ["**"])

            assert { :ok, _ } = Resx.Resource.open("file://#{__DIR__}/file_test.exs")
            assert { :ok, _ } = Resx.Resource.open("file://#{__DIR__}/data_test.exs")
            assert { :ok, _ } = Resx.Resource.open("file://#{__DIR__}/transform_test.exs")

            assert { :ok, _ } = Resx.Resource.open("file://#{node_a}#{__DIR__}/file_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open("file://#{node_a}#{__DIR__}/data_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open("file://#{node_a}#{__DIR__}/transform_test.exs")

            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open("file://#{node_b}#{__DIR__}/file_test.exs")
            assert { :ok, _ } = Resx.Resource.open("file://#{node_b}#{__DIR__}/data_test.exs")
            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open("file://#{node_b}#{__DIR__}/transform_test.exs")


            assert { :ok, _ } = :rpc.call(node_a, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/file_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/data_test.exs"])
            assert { :ok, _ } = :rpc.call(node_a, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/transform_test.exs"])

            assert { :ok, _ } = :rpc.call(node_a, Resx.Resource, :open, ["file://#{__DIR__}/file_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{__DIR__}/data_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{__DIR__}/transform_test.exs"])

            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{node_b}#{__DIR__}/file_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{node_b}#{__DIR__}/data_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_a, Resx.Resource, :open, ["file://#{node_b}#{__DIR__}/transform_test.exs"])


            assert { :ok, _ } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/file_test.exs"])
            assert { :ok, _ } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/data_test.exs"])
            assert { :ok, _ } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{node()}#{__DIR__}/transform_test.exs"])

            assert { :ok, _ } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{node_a}#{__DIR__}/file_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_b, Resx.Resource, :open, ["file://#{node_a}#{__DIR__}/data_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_b, Resx.Resource, :open, ["file://#{node_a}#{__DIR__}/transform_test.exs"])

            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_b, Resx.Resource, :open, ["file://#{__DIR__}/file_test.exs"])
            assert { :ok, _ } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{__DIR__}/data_test.exs"])
            assert { :error, { :invalid_reference, "protected file" } } == :rpc.call(node_b, Resx.Resource, :open, ["file://#{__DIR__}/transform_test.exs"])


            { :ok, resource } = :rpc.call(node_b, Resx.Resource, :open, ["file://#{node_a}#{__DIR__}/file_test.exs"])
            assert { :ok, _ } = Resx.Resource.open(resource)

            :rpc.call(node_b, Application, :put_env, [:resx, Resx.Producers.File, [access: []]])
            assert { :ok, _ } = Resx.Resource.open(resource)

            Application.put_env(:resx, Resx.Producers.File, access: [])
            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open(resource)

            Application.put_env(:resx, Resx.Producers.File, access: ["**"])
            :rpc.call(node_a, Application, :put_env, [:resx, Resx.Producers.File, [access: []]])
            assert { :error, { :invalid_reference, "protected file" } } == Resx.Resource.open(resource)

            :rpc.call(node_a, Application, :put_env, [:resx, Resx.Producers.File, [access: ["**/test/resx/producers/file_test.exs"]]])
            assert { :ok, %{ content: content } } = Resx.Resource.stream(resource)
            assert ["defmodule Resx.Producers.FileTest do\n"] == Enum.take(content, 1)

            :rpc.call(node_a, Application, :put_env, [:resx, Resx.Producers.File, [access: [""]]])
            catch_error Enum.take(content, 1)
        end
    end

    test "uri/1" do
        Application.put_env(:resx, Resx.Producers.File, access: ["**"])
        { :ok, resource } = Resource.open("file://#{__DIR__}/file_test.exs")

        assert { :ok, URI.encode("file://#{node()}#{__DIR__}/file_test.exs") } == Resource.uri(resource)

        Application.put_env(:resx, Resx.Producers.File, access: [])
        assert { :error, { :invalid_reference, _ } } = Resource.uri(resource)
    end

    test "exists?/1" do
        Application.put_env(:resx, Resx.Producers.File, access: ["**"])

        assert { :ok, true } == Resource.exists?("file://#{__DIR__}/file_test.exs")
        assert { :ok, false } == Resource.exists?("file://#{__DIR__}/file_test2.exs")

        Application.put_env(:resx, Resx.Producers.File, access: [])
        assert { :error, { :invalid_reference, _ } } = Resource.exists?("file://#{__DIR__}/file_test.exs")
        assert { :error, { :invalid_reference, _ } } = Resource.exists?("file://#{__DIR__}/file_test2.exs")
    end

    test "alike?/2" do
        Application.put_env(:resx, Resx.Producers.File, access: ["**"])

        assert true == Resource.alike?("file://#{__DIR__}/file_test.exs", "file://#{__DIR__}/file_test.exs")
        assert false == Resource.alike?("file://#{__DIR__}/file_test.exs", "file://#{__DIR__}/file_test2.exs")

        Application.put_env(:resx, Resx.Producers.File, access: [])
        assert false == Resource.alike?("file://#{__DIR__}/file_test.exs", "file://#{__DIR__}/file_test.exs")
        assert false == Resource.alike?("file://#{__DIR__}/file_test.exs", "file://#{__DIR__}/file_test2.exs")
    end

    describe "attributes" do
        test "keys" do
            Application.put_env(:resx, Resx.Producers.File, access: ["**"])
            { :ok, resource } = Resource.open("file://#{__DIR__}/file_test.exs")

            assert { :ok, keys } = Resource.attribute_keys(resource)

            [:__struct__|result] = Enum.sort([:name|Map.keys(%File.Stat{})])
            assert result == Enum.sort(keys)

            Application.put_env(:resx, Resx.Producers.File, access: [])
            assert { :error, { :invalid_reference, _ } } = Resource.attribute_keys(resource)
        end

        test "name field" do
            Application.put_env(:resx, Resx.Producers.File, access: ["**"])
            { :ok, resource } = Resource.open("file://#{__DIR__}/file_test.exs")

            assert { :ok, "file_test.exs" } == Resource.attribute(resource, :name)

            Application.put_env(:resx, Resx.Producers.File, access: [])
            assert { :error, { :invalid_reference, _ } } = Resource.attribute(resource, :name)
        end
    end
end
