defmodule Resx.Producers.File do
    @moduledoc """
      A producer to handle file URIs.

        Resx.Producers.File.open("file:///path/to/file.txt")

      ### Types

      MIME types are inferred from file extension names. A chained file extension
      will result in multiple MIME types (e.g. `file.jpg.txt => ["text/plain", "image/jpeg"]`).
      Unsupported types will default to `"application/octet-stream"`. Custom MIME
      types can be added to the config.

      ### Hostnames

      Valid hostnames can either be an erlang node name, `localhost`, or not
      specified.

      When referencing a file without providing a hostname or using `localhost`,
      the file will be referenced from the calling node. This means that if a
      reference was created and has been passed to another node, any requests that
      need to access this file will then be sent back to the original node to be
      processed.

      ### Files/Directory Access

      Files that can be opened need to be explicitly included. This can be done by
      configuring the `:access` configuration option for `Resx.Producers.File`.

        config :resx, Resx.Producers.File,
            access: [
                "path/to/file.txt",
                "path/*/*.jpg",
                "**/*.{ex,exs}",
                ~r/.*?\/to\/another.txt/,
                { MyFileAccessGranter, :can_access?, 1 },
                { :"foo@127.0.0.1", "**/some-file.txt" },
                { &(&1 in [:"foo@127.0.0.1", :"bar@127.0.0.1"]), "**/another-file.txt" }
            ]

      The `:access` field should contain either a list of strings, regexes, or
      callback functions, which will be applied to every node or it can be tagged
      with the node (`{ node, pattern }`) if the rule should only be applied to
      files found at that node. Callback functions expect a string (glob pattern)
      and return a boolean. The node may also be a callback function that expects
      a node and returns a boolean. Valid function formats are any callback variant,
      see `Callback` for more information.

      File access rules are applied both on the node making the request and the
      node processing the request. This means that if node `foo@127.0.0.1` has the
      access rules:

        [
            "/one.txt",
            {:"foo@127.0.0.1", "/two.txt"},
            {:"bar@127.0.0.1", "/three.txt"}
        ]

      And node `bar@127.0.0.1` has the access rules:

        [
            "/two.txt",
            {:"bar@127.0.0.1", "/three.txt"}
        ]

      If node `foo@127.0.0.1` attempted to open the following files it would get
      these responses:

        \# Allowed
        Resx.Producers.File.open("file:///one.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://foo@127.0.0.1/one.txt") \# => open file on node foo@127.0.0.1

        Resx.Producers.File.open("file:///two.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://foo@127.0.0.1/two.txt") \# => open file on node foo@127.0.0.1

        Resx.Producers.File.open("file://bar@127.0.0.1/three.txt") \# => open file on node bar@127.0.0.1

        \# Not Allowed
        Resx.Producers.File.open("file://bar@127.0.0.1/one.txt")

        Resx.Producers.File.open("file://bar@127.0.0.1/two.txt")

        Resx.Producers.File.open("file:///three.txt")
        Resx.Producers.File.open("file://foo@127.0.0.1/three.txt")


      If node `bar@127.0.0.1` attempted to open the following files it would get
      these responses:

        \# Allowed
        Resx.Producers.File.open("file:///two.txt") \# => open file on node bar@127.0.0.1
        Resx.Producers.File.open("file://foo@127.0.0.1/two.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://bar@127.0.0.1/two.txt") \# => open file on node bar@127.0.0.1

        Resx.Producers.File.open("file:///three.txt") \# => open file on node bar@127.0.0.1
        Resx.Producers.File.open("file://bar@127.0.0.1/three.txt") \# => open file on node bar@127.0.0.1

        \# Not Allowed
        Resx.Producers.File.open("file:///one.txt")
        Resx.Producers.File.open("file://foo@127.0.0.1/one.txt")
        Resx.Producers.File.open("file://bar@127.0.0.1/one.txt")

        Resx.Producers.File.open("file://foo@127.0.0.1/three.txt")

      One common rule for nodes that might access files from other nodes, is a
      generic catch-all. This rule can be written as: `{ &(&1 != node()), "**" }`
      This will allow the calling node to attempt to access any file on the
      recieving node.

      #### Glob Pattern

      Glob pattern rules follow the syntax of `Path.wildcard/2`, with the addition
      of an negative character match `[!char1,char2,...]`. e.g. `[!abc]` or `[!a-c]`
      (match any character other than `a`, `b`, or `c`).

      #### Distribution

      The following operations need to talk to the node the file originates from.

      * Opening a file
      * Checking if a file exists
      * Accessing a file's attributes

      These distributed requests are done using the `rpc` module provided by
      the erlang runtime. This can be overridden by configuring the `:rpc` field
      to a callback function that will be used as the replacement rpc handler. The
      callback function expects 4 arguments (node, module, fun, args) and should
      return the result of target function otherwise any non-ok/error tuple to be
      used as the internal error. Valid function formats are any callback variant,
      see `Callback` for more information.

        config :resx, Resx.Producers.File,
            rpc: { :gen_rpc, :call, 4 }

      Resources contain a reference to the node they came from. So if a resource
      is passed around to other nodes, it will still be able to guarantee access.

      An example of this is in the diagram below. If `foo@127.0.0.1` requests to
      open a file on `bar@127.0.0.1`, and then passes the resource to `baz@127.0.0.1`
      which then wants to repoen it (get the latest changes) the request will go
      back to `bar@127.0.0.1`.

      ```bob
      +---------------+                   +---------------+
      |               | ----- open -----> |               |
      | foo@127.0.0.1 |                   |               |
      |               | <--- resource --- |               |
      +---------------+                   |               |
              |                           |               |
          resource                        | bar@127.0.0.1 |
              |                           |               |
              v                           |               |
      +---------------+                   |               |
      |               | ---- reopen ----> |               |
      | baz@127.0.0.1 |                   |               |
      |               | <--- resource --- |               |
      +---------------+                   +---------------+
      ```

      ### Streams

      File streaming relies on the `File.Stream` type, but allows for distributed
      access. These follow the same distribution rules as previously outlined,
      with the addition that operations on the stream will be sent back to the
      node the file originates from.

      #### Caveats

      One caveat to this approach however, is because access to the file is deferred,
      the identity of this resource will not be accurate. The timestamp will be the
      file timestamp at the time of first creating the resource, not necessarily the
      file timestamp at the time of operating on the content stream.

      ### Sources

      File sources are file references with a backup data source, so if the file no
      longer exists it will revert back to getting the data from the source and
      creating the file again. The data source is any compatible URI.

        Resx.Producers.File.open("file:///hi.txt?source=ZGF0YTp0ZXh0L3BsYWluO2NoYXJzZXQ9VVMtQVNDSUk7YmFzZTY0LGFHaz0=")

      If the source cannot be accessed anymore but the file exists, it will access
      the file. If both cannot be accessed then the request will fail.

      #### Caching

      File sources can act a form of cache, a couple of scenarios you might want to
      cache could be:

      * Storing a copy of a file locally that originates from another node in the
      network. So for as long as the file remains on the local node, any future
      requests won't need to be sent across the network.
      * Storing a file that is created from a chain of operations on a resource. So
      future requests won't need to reprocess the original pipeline but can simply
      access the file directly.

      However there are some downsides to relying on it as a proper cache (or at least
      require additional work):

      * As the file reference will not be recreated unless it no longer exists, this
      can mean that the data source is does not represent the current state of the
      file. In order to invalidate the file it will need to be deleted.
      * Recreating a file from a data source is __not atomic__, this can mean that
      if there are multiple processes trying to operate on the file, some or all of
      them may go through the process of creating the file from the data source. If
      the data source contains a side-effect, or simply the referenced data changes,
      the new file could be different from what some of the other processes will
      receive.
    """
    use Resx.Producer
    use Resx.Storer
    require Callback

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity

    defmodule ProtectedFileError do
        defexception [:message, :node, :path]

        @impl Exception
        def exception({ node, path }) do
            %ProtectedFileError{
                message: "unable to access the protected file #{path} on #{node}",
                node: node,
                path: path
            }
        end
    end

    defp to_path(%Reference{ repository: { node, path, source } }), do: check_access(node, path, source)
    defp to_path(%URI{ scheme: "file", path: nil }), do: { :error, { :invalid_reference, "no file path was specified" } }
    defp to_path(%URI{ scheme: "file", host: host, path: path, userinfo: nil, query: query }) when host in [nil, "localhost"], do: check_access(node(), path, decode_source(query))
    defp to_path(%URI{ scheme: "file", host: host, path: path, userinfo: user, query: query }) when not is_nil(user), do: check_access(String.to_atom(user <> "@" <> host), path, decode_source(query))
    defp to_path(%URI{ scheme: "file" }), do: { :error, { :invalid_reference, "only supports local or remote node file references" } }
    defp to_path(uri) when is_binary(uri), do: URI.decode(uri) |> URI.parse |> to_path
    defp to_path(_), do: { :error, { :invalid_reference, "not a file reference" } }

    defp decode_source(nil), do: nil
    defp decode_source(query) do
        case URI.decode_query(query) do
            %{ "source" => data } -> Base.decode64(data)
            _ -> nil
        end
    end

    defp store_meta(data, { :meta, path, meta }) do
        File.write!(path <> ".meta", :erlang.term_to_binary(meta))
        { [data], nil }
    end
    defp store_meta(data, _), do: { [data], nil }

    defp store_content(node, path, content, meta) do
        %Content.Stream{
            type: mime(path),
            data: %__MODULE__.Stream{
                stream: Content.Stream.new(content) |> Stream.into(File.stream!(path)) |> Stream.transform({ :meta, path, meta }, &store_meta/2),
                node: node,
                path: path
            }
        }
    end

    defp store({ node, path, reference = %Reference{} }) do
        case Resource.stream(reference) do
            { :ok, resource } -> store({ node, path, resource })
            error -> error
        end
    end
    defp store({ node, path, resource }), do: { :ok, { node, path, %{ resource | content: store_content(node, path, resource.content, resource.meta) } } }

    defp check_access(node, path, { :ok, source }) do
        case Resource.stream(source) do
            { :ok, resource } ->
                case check_access(node, path, resource) do
                    { :ok, repo } -> store(repo)
                    error -> error
                end
            error -> error
        end
    end
    defp check_access(_, _, :error), do: { :error, { :invalid_reference, "source is not base64" } }
    defp check_access(node, path, source) do
        if Enum.any?(config(:access, []), fn
            { ^node, access } -> include_path?(path, access)
            { match_node, access } when Callback.is_callback(match_node) -> if(Callback.call(match_node, [node]), do: include_path?(path, access), else: false)
            { _, _ } -> false
            access -> include_path?(path, access)
        end) do
            { :ok, { node, path, source } }
        else
            { :error, { :invalid_reference, "protected file" } }
        end
    end

    @doc """
      Get the MIME type list for the filename.

        iex> Resx.Producers.File.mime("foo.txt")
        ["text/plain"]

        iex> Resx.Producers.File.mime("foo.txt.png.jpg")
        ["image/jpeg", "image/png", "text/plain"]

        iex> Resx.Producers.File.mime("foo")
        ["application/octet-stream"]

        iex> Resx.Producers.File.mime("a/b/foo.txt")
        ["text/plain"]

        iex> Resx.Producers.File.mime("a.png/b.exe/foo.txt")
        ["text/plain"]

        iex> Resx.Producers.File.mime(".txt")
        ["application/octet-stream"]

        iex> Resx.Producers.File.mime(".txt.png")
        ["image/png"]
    """
    @spec mime(String.t) :: Content.type
    def mime(path) do
        Path.basename(path)
        |> String.split(".", trim: true)
        |> case do
            [_, extension] -> [MIME.type(extension)]
            [_] -> ["application/octet-stream"]
            [_|extensions] -> Enum.reduce(extensions, [], &([MIME.type(&1)|&2]))
        end
    end

    defp timestamp(path) do
        case File.stat(path, time: :posix) do
            { :ok, %File.Stat{ mtime: timestamp } } -> timestamp
            error -> error
        end
    end

    defp meta_contents(path) do
        case File.read(path) do
            { :ok, meta } ->
                try do
                    { :ok, :erlang.binary_to_term(meta) }
                rescue
                    e -> { :error, { :internal, e } }
                end
            error -> error
        end
    end

    defp format_posix_error({ :error, :enoent }, path), do: { :error, { :unknown_resource, path } }
    defp format_posix_error({ :error, reason }, _), do: { :error, { :internal, reason } }

    defp include_path?(path, regex = %Regex{}), do: Regex.match?(regex, path)
    defp include_path?(path, glob) when is_binary(glob) or is_list(glob), do: PathMatch.match?(glob, path)
    defp include_path?(path, fun), do: Callback.call(fun, [path])

    defp config(key, default \\ nil) do
        Application.get_env(:resx, __MODULE__)[key] || default
    end

    defp access?(node, opts) do
        path = opts[:path]
        if is_nil(path) or opts[:checked] do
            :ok
        else
            case check_access(node, path, nil) do
                { :ok, _ } -> :ok
                error ->
                    if opts[:exception] do
                        raise ProtectedFileError, { node, path }
                    else
                        error
                    end
            end
        end
    end

    @doc false
    def call(module, fun, args, opts), do: call(node(), module, fun, args, opts)

    @doc false
    def call(node, module, fun, args, opts) do
        case access?(node, opts) do
            :ok ->
                case node() do
                    ^node -> apply(module, fun, args)
                    _ ->
                        rpc = config(:rpc, { :rpc, :call, 4 })
                        Callback.call(rpc, [node, __MODULE__, :call, [module, fun, args, [{ :checked, false }|opts]]])
                end
            error -> error
        end
    end

    defp module_call(node, fun, args, opts \\ []) do
        case call(node, __MODULE__, fun, args, opts) do
            :ok -> :ok
            result = { type, _ } when type in [:ok, :error] -> result
            reason -> { :error, { :internal, reason } }
        end
    end

    @doc false
    def file_open(repo = { _, path, nil }) do
        with { :read, { :ok, data } } <- { :read, File.read(path) },
             { :stat, timestamp } when is_integer(timestamp) <- { :stat, timestamp(path) } do
                content = %Content{
                    type: mime(path),
                    data: data
                }
                resource = %Resource{
                    reference: %Reference{
                        adapter: __MODULE__,
                        repository: repo,
                        integrity: %Integrity{
                            timestamp: timestamp
                        }
                    },
                    content: content
                }

                { :ok, resource }
        else
            { _, error } -> format_posix_error(error, path)
        end
    end
    def file_open(repo = { node, path, source }) do
        with { :read, { :ok, data } } <- { :read, File.read(path) },
             { :meta, { :ok, meta } } <- { :meta, meta_contents(path <> ".meta") },
             { :stat, timestamp } when is_integer(timestamp) <- { :stat, timestamp(path) } do
                content = %Content{
                    type: mime(path),
                    data: data
                }
                resource = %Resource{
                    reference: %Reference{
                        adapter: __MODULE__,
                        repository: { node, path, Resx.ref(source) },
                        integrity: %Integrity{
                            timestamp: timestamp
                        }
                    },
                    content: content,
                    meta: meta
                }

                { :ok, resource }
        else
            _ ->
                case source do
                    %Reference{} -> store(repo)
                    _ -> { :ok, repo }
                end
                |> case do
                    { :ok, { node, path, resource } } ->
                        try do
                            Content.new(resource.content)
                        rescue
                            e -> { :error, { :internal, e } }
                        else
                            content ->
                                reference = %Reference{
                                    adapter: __MODULE__,
                                    repository: { node, path, resource.reference },
                                    integrity: %Integrity{
                                        timestamp: timestamp(path)
                                    }
                                }
                                { :ok, %{ resource | reference: reference, content: content } }
                        end
                    error -> error
                end
        end
    end

    @doc false
    def file_stream(repo = { node, path, nil }, opts) do
        stream = File.stream!(path, opts[:modes] || [], opts[:bytes] || :line)
        case timestamp(path) do
            timestamp when is_integer(timestamp) ->
                content = %Content.Stream{
                    type: mime(path),
                    data: %__MODULE__.Stream{ stream: stream, node: node, path: path }
                }
                resource = %Resource{
                    reference: %Reference{
                        adapter: __MODULE__,
                        repository: repo,
                        integrity: %Integrity{
                            timestamp: timestamp
                        }
                    },
                    content: content
                }

                { :ok, resource }
            error -> format_posix_error(error, path)
        end
    end
    def file_stream(repo = { node, path, source }, opts) do
        content = %Content.Stream{
            type: mime(path),
            data: %__MODULE__.Stream{
                stream: Stream.resource(fn ->
                    if File.exists?(path) do
                        File.stream!(path, opts[:modes] || [], opts[:bytes] || :line)
                    else
                        case source do
                            %Reference{} -> store(repo)
                            _ -> { :ok, repo }
                        end
                        |> case do
                            { :ok, { _, _, resource } } -> Content.Stream.new(resource.content)
                            error -> throw error
                        end
                    end
                end, fn
                    nil -> { :halt, nil }
                    stream -> { stream, nil }
                end, &(&1)),
                node: node,
                path: path
            }
        }

        with { :meta, { :ok, meta } } <- { :meta, meta_contents(path <> ".meta") },
             { :stat, timestamp } when is_integer(timestamp) <- { :stat, timestamp(path) } do
                resource = %Resource{
                    reference: %Reference{
                        adapter: __MODULE__,
                        repository: { node, path, Resx.ref(source) },
                        integrity: %Integrity{
                            timestamp: timestamp
                        }
                    },
                    content: content,
                    meta: meta
                }

                { :ok, resource }
        else
            _ ->
                case source do
                    %Reference{} -> store(repo)
                    _ -> { :ok, repo }
                end
                |> case do
                    { :ok, { node, path, resource } } ->
                        reference = %Reference{
                            adapter: __MODULE__,
                            repository: { node, path, resource.reference },
                            integrity: %Integrity{
                                timestamp: DateTime.to_unix(DateTime.utc_now)
                            }
                        }
                        { :ok, %{ resource | reference: reference, content: content } }
                    error -> error
                end
        end
    end

    @doc false
    def file_exists?({ _, path, nil }), do: { :ok, File.exists?(path) }
    def file_exists?({ _, path, source }), do: if(File.exists?(path), do: { :ok, true }, else: Resource.exists?(source))

    @doc false
    def file_attributes(path) do
        case File.stat(path, time: :posix) do
            { :ok, stat } ->
                attributes =
                    Map.delete(stat, :__struct__)
                    |> Map.put(:name, Path.basename(path))

                { :ok, attributes }
            error -> format_posix_error(error, path)
        end
    end

    @doc false
    def file_store(node, path, content, meta, opts) do
        stream = Stream.resource(fn ->
            if File.exists?(path) do
                File.stream!(path, opts[:modes] || [], opts[:bytes] || :line)
            else
                store_content(node, path, content, meta)
            end
        end, fn
            nil -> { :halt, nil }
            stream -> { stream, nil }
        end, &(&1))

        { :ok, stream }
    end

    @doc false
    def file_delete(path, meta, content) do
        with { :delete, :ok, _ } <- { :delete, if(meta, do: File.rm(path <> ".meta"), else: :ok), path <> ".meta" },
             { :delete, :ok, _ } <- { :delete, if(content, do: File.rm(path), else: :ok), path } do
                :ok
        else
            { :delete, error, path } -> format_posix_error(error, path)
        end
    end

    @impl Resx.Producer
    def schemes(), do: ["file"]

    @impl Resx.Producer
    def open(reference, _ \\ []) do
        case to_path(reference) do
            { :ok, repo = { node, path, _ } } -> module_call(node, :file_open, [repo], path: path, checked: true)
            error -> error
        end
    end

    @doc """
      Creates a file resource with streamable contents.

      The options expose the additional arguments that can normally be passed to
      `File.stream!/3`.

      * `:modes` - expects a value of type `File.stream_mode`. If no modes are provided
      it defaults to the default modes `File.stream!/3` opens with.
      * `:bytes` - expects a positive integer for the number bytes to read per request.
      If it is not provided, it defaults to reading line by line.
    """
    @impl Resx.Producer
    @spec stream(Resx.ref, [modes: File.stream_mode, bytes: pos_integer]) :: { :ok, resource :: Resource.t(Content.Stream.t) } | Resx.error(Resx.resource_error | Resx.reference_error)
    def stream(reference, opts \\ []) do
        case to_path(reference) do
            { :ok, repo = { node, path, _ } } -> module_call(node, :file_stream, [repo, opts], path: path, checked: true)
            error -> error
        end
    end

    @impl Resx.Producer
    def exists?(reference) do
        case to_path(reference) do
            { :ok, repo = { node, path, _ } } -> module_call(node, :file_exists?, [repo], path: path, checked: true)
            error -> error
        end
    end

    @impl Resx.Producer
    def alike?(a, b) do
        with { :a, { :ok, { node, path, _ } } } <- { :a, to_path(a) },
             { :b, { :ok, { ^node, ^path, _ } } } <- { :b, to_path(b) } do
                true
        else
            _ -> false
        end
    end

    @impl Resx.Producer
    def source(reference) do
        case to_path(reference) do
            { :ok, { _, _, source } } -> { :ok, source }
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_uri(reference) do
        case to_path(reference) do
            { :ok, { node, path, nil } } -> { :ok, URI.encode("file://" <> to_string(node) <> path) }
            { :ok, { node, path, source } } ->
                case Resource.uri(source) do
                    { :ok, uri } -> { :ok, URI.encode("file://" <> to_string(node) <> path <> "?source=#{Base.encode64(uri)}") }
                    error -> error
                end
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attributes(reference) do
        case to_path(reference) do
            { :ok, { node, path, source } } ->
                case module_call(node, :file_attributes, [path], path: path, checked: true) do
                    error = { :error, { :unknown_resource, _ } } ->
                        case source do
                            nil -> error
                            source -> Resource.attributes(source)
                        end
                    result -> result
                end
            error -> error
        end
    end

    @impl Resx.Storer
    def source_compatibility(_), do: { :compatible, :internal }

    @impl Resx.Storer
    def prepare_store(reference) do
        case to_path(reference) do
            { :ok, { node, path, _ } } -> [path: path, node: node]
            _ -> []
        end
    end

    @doc """
      Store a resource as a file.

      File stores are deferred, this means the returned resource will contain a content
      stream. When the content stream is processed the store operation will be performed.

      It should also be noted that like file sources, file stores are non-atomic.

      The required options are:

      * `:path` - expects a string denoting the path the file will be stored at. If
      it is not an absolute path, the path will be expanded by the calling node (this
      may result in the wrong path if it's storing on an external node).

      The following options are all optional:

      * `:node` - expects a node name for where the resource should be stored.
      * `:modes` - expects a value of type `File.stream_mode`. If no modes are provided
      it defaults to the default modes `File.stream!/3` opens with.
      * `:bytes` - expects a positive integer for the number bytes to read per request.
      If it is not provided, it defaults to reading line by line.
    """
    @impl Resx.Storer
    @spec store(Resource.t, [path: String.t, node: node, modes: File.stream_mode, bytes: pos_integer]) :: { :ok, resource :: Resource.t(Content.Stream.t) } | Resx.error
    def store(resource, options) do
        case Keyword.fetch(options, :path) do
            { :ok, path } ->
                [user, host] = case options[:node] do
                    nil -> [nil, nil]
                    node -> to_string(node) |> String.split("@")
                end

                path = Path.expand(path)
                case to_path(%URI{ scheme: "file", host: host, path: path, userinfo: user }) do
                    { :ok, { node, path, _ } } ->
                        case module_call(node, :file_store, [node, path, resource.content, resource.meta, options], path: path, checked: true) do
                            { :ok, stream } ->
                                content = %Content.Stream{
                                    type: mime(path),
                                    data: %__MODULE__.Stream{
                                        stream: stream,
                                        node: node,
                                        path: path
                                    }
                                }
                                reference = %Reference{
                                    adapter: __MODULE__,
                                    repository: { node, path, resource.reference },
                                    integrity: %Integrity{
                                        timestamp: DateTime.to_unix(DateTime.utc_now)
                                    }
                                }
                                { :ok, %{ resource | reference: reference, content: content } }
                            error -> error
                        end
                    error -> error
                end
            _ -> { :error, { :internal, "a store :path must be specified" } }
        end
    end

    @doc """
      Discard a file resource.

      The following options are all optional:

      * `:meta` - specify whether the meta file should also be deleted. By default
      it is.
      * `:content` - specify whether the content file should also be deleted. By
      default it is.
    """
    @impl Resx.Storer
    @spec discard(Resx.ref, [meta: boolean, content: boolean]) :: :ok | Resx.error(Resx.resource_error | Resx.reference_error)
    def discard(reference, opts) do
        case to_path(reference) do
            { :ok, { node, path, _ } } -> module_call(node, :file_delete, [path, opts[:meta] != false, opts[:content] != false], path: path, checked: true)
            error -> error
        end
    end
end
