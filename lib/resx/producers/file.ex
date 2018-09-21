defmodule Resx.Producers.File do
    use Resx.Producer

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    defp to_path(%Reference{ repository: path }), do: { :ok, path }
    defp to_path(%URI{ scheme: "file", path: path }), do: { :ok, path }
    defp to_path(uri) when is_binary(uri), do: URI.decode(uri) |> URI.parse |> to_path
    defp to_path(_), do: { :error, { :invalid_reference, "not a file reference" } }

    defp extensions(path) do
        Path.basename(path)
        |> String.split(".", trim: true)
        |> case do
            [_, extension] -> extension
            [_] -> nil
            [_|extensions] -> extensions
        end
    end

    defp timestamp(path) do
        case File.stat(path, time: :posix) do
            { :ok, %File.Stat{ mtime: timestamp } } -> timestamp
            error -> error
        end
    end

    defp format_posix_error({ :error, :enoent }, path), do: { :error, { :unknown_resource, path } }
    defp format_posix_error({ :error, reason }, _), do: { :error, { :internal, reason } }

    @impl Resx.Producer
    def open(reference) do
        case to_path(reference) do
            { :ok, path } ->
                with { :read, { :ok, data } } <- { :read, File.read(path) },
                     { :stat, timestamp } when is_integer(timestamp) <- { :stat, timestamp(path) } do
                        content = %Content{
                            type: extensions(path),
                            data: data
                        }
                        resource = %Resource{
                            reference: %Reference{
                                adapter: __MODULE__,
                                repository: path,
                                integrity: %Integrity{
                                    checksum: Resource.hash(content),
                                    timestamp: timestamp
                                }
                            },
                            content: content
                        }

                        { :ok,  resource }
                else
                    { _, error } -> format_posix_error(error, path)
                end
            error -> error
        end
    end

    @impl Resx.Producer
    def exists?(reference) do
        case to_path(reference) do
            { :ok, path } -> { :ok, File.exists?(path) }
            error -> error
        end
    end

    @impl Resx.Producer
    def alike?(a, b) do
        with { :a, { :ok, path } } <- { :a, to_path(a) },
             { :b, { :ok, ^path } } <- { :b, to_path(b) } do
                true
        else
            _ -> false
        end
    end

    @impl Resx.Producer
    def resource_uri(reference) do
        case to_path(reference) do
            { :ok, path } -> { :ok, URI.encode("file://" <> path) }
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attributes(reference) do
        case to_path(reference) do
            { :ok, path } ->
                case File.stat(path, time: :posix) do
                    { :ok, stat } ->
                        attributes =
                            Map.delete(stat, :__struct__)
                            |> Map.put(:name, Path.basename(path))

                        { :ok, attributes }
                    error -> format_posix_error(error, path)
                end
            error -> error
        end
    end
end
