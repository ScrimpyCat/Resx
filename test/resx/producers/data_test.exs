defmodule Resx.Producers.DataTest do
    use ExUnit.Case
    doctest Resx.Producers.Data

    alias Resx.Resource

    test "exists?/1" do
        assert { :ok, true } == Resource.exists?("data:,test")
        assert { :ok, true } == Resource.exists?("data:text/plain;base64,SGVsbG8sIFdvcmxkIQ%3D%3D")
    end
end
