defmodule Resx.Producers.DataTest do
    use ExUnit.Case
    doctest Resx.Producers.Data

    alias Resx.Resource

    test "exists?/1" do
        assert { :ok, true } == Resource.exists?("data:,test")
        assert { :ok, true } == Resource.exists?("data:text/plain;base64,SGVsbG8sIFdvcmxkIQ%3D%3D")
    end

    test "alike?/2" do
        assert true == Resource.alike?("data:,test", "data:,test")
        assert true == Resource.alike?("data:,test", "data:text/plain;charset=US-ASCII,test")
        assert true == Resource.alike?("data:,test", "data:text/plain;charset=US-ASCII;base64,dGVzdA==")
        assert false == Resource.alike?("data:,test", "data:text/plain;charset=US-ASCII;base64,SGVsbG8sIFdvcmxkIQ%3D%3D")
        assert false == Resource.alike?("data:,test", "data:text/plain;base64,dGVzdA==")
        assert false == Resource.alike?("data:,test", "data:base64,dGVzdA==")
    end

    test "source/1" do
        assert { :ok, nil } == Resource.source("data:,test")
    end
end
