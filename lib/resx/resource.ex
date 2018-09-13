defmodule Resx.Resource do
    defstruct [:content]

    alias Resx.Resource
    alias Resx.Resource.Reference.Integrity

    @type t :: %Resource{
        content: Resource.Content.t
    }

    @doc """
      Compute a hash of the resource content using the default hashing function.

      See `hash/2` for more information.
    """
    @spec hash(t) :: Integrity.checksum
    def hash(resource) do
        hash(resource, Application.get_env(:resx, :hash, :sha))
    end

    @doc """
      Compute a hash of the resource content.

      Meta information and resource references are not included in the hash.
    """
    @spec hash(t, Integrity.algo | { Integrity.algo, fun | mfa | { module, atom, list } | { module, atom, list, non_neg_integer } }) :: Integrity.checksum
    def hash(resource, { algo, { module, fun, args, index } }) do
        { algo, apply(module, fun, List.insert_at(args, index, to_binary(resource))) }
    end
    def hash(resource, { algo, { module, fun, 1 } }) do
        { algo, apply(module, fun, [to_binary(resource)]) }
    end
    def hash(resource, { algo, { module, fun, args } }) do
        { algo, apply(module, fun, args ++ [to_binary(resource)]) }
    end
    def hash(resource, { algo, fun }) when is_function(algo) do
        { algo, fun.(to_binary(resource)) }
    end
    def hash(resource, algo) do
        { algo, :crypto.hash(algo, to_binary(resource)) }
    end

    defp to_binary(%Resource{ content: content }), do: to_binary(content)
    defp to_binary(%Resource.Content{ type: type, data: data }), do: :erlang.term_to_binary({ type, data })
end
