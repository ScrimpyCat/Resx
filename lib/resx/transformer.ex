defmodule Resx.Transformer do
    alias Resx.Resource

    @callback transform(Resource.t) :: { :ok, resource :: Resource.t } | Resx.error
end
