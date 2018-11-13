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
                { :"foo@127.0.0.1", "**/some-file.txt" }
            ]

      The `:access` field should contain either a list of strings, regexes, or
      callback functions, which will be applied to every node or it can be tagged
      with the node (`{ node, pattern }`) if the rule should only be applied to
      files found at that node. Callback functions expect a string (glob pattern)
      and return a boolean. Valid function formats are any callback variant, see
      `Resx.Callback` for more information.

      File access rules are applied on the node making the request. This means
      that if node `foo@127.0.0.1` has the access rules:

        [
            "/one.txt",
            {:"foo@127.0.0.1", "/two.txt"},
            {:"bar@127.0.0.1", "/three.txt"}
        ]

      And node `bar@127.0.0.1` has the access rules:

        [
            {:"bar@127.0.0.1", "/three.txt"}
        ]

      If node `foo@127.0.0.1` attempted to open the following files it would get
      these responses:

        \# Allowed
        Resx.Producers.File.open("file:///one.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://foo@127.0.0.1/one.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://bar@127.0.0.1/one.txt") \# => open file on node bar@127.0.0.1

        Resx.Producers.File.open("file:///two.txt") \# => open file on node foo@127.0.0.1
        Resx.Producers.File.open("file://foo@127.0.0.1/two.txt") \# => open file on node foo@127.0.0.1

        Resx.Producers.File.open("file://bar@127.0.0.1/three.txt") \# => open file on node bar@127.0.0.1

        \# Not Allowed
        Resx.Producers.File.open("file://bar@127.0.0.1/two.txt")

        Resx.Producers.File.open("file:///three.txt")
        Resx.Producers.File.open("file://foo@127.0.0.1/three.txt")


      If node `bar@127.0.0.1` attempted to open the following files it would get
      these responses:

        \# Allowed
        Resx.Producers.File.open("file:///three.txt") \# => open file on node bar@127.0.0.1
        Resx.Producers.File.open("file://bar@127.0.0.1/three.txt") \# => open file on node bar@127.0.0.1

        \# Not Allowed
        Resx.Producers.File.open("file:///one.txt")
        Resx.Producers.File.open("file://foo@127.0.0.1/one.txt")
        Resx.Producers.File.open("file://bar@127.0.0.1/one.txt")

        Resx.Producers.File.open("file:///two.txt")
        Resx.Producers.File.open("file://foo@127.0.0.1/two.txt")
        Resx.Producers.File.open("file://bar@127.0.0.1/two.txt")

        Resx.Producers.File.open("file://foo@127.0.0.1/three.txt")

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
      see `Resx.Callback` for more information.

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
    """
    use Resx.Producer

    alias Resx.Resource
    alias Resx.Resource.Content
    alias Resx.Resource.Reference
    alias Resx.Resource.Reference.Integrity
    alias Resx.Callback

    defp to_path(%Reference{ repository: { node, path } }), do: check_access(node, path)
    defp to_path(%URI{ scheme: "file", host: host, path: path, userinfo: nil }) when host in [nil, "localhost"], do: check_access(node(), path)
    defp to_path(%URI{ scheme: "file", host: host, path: path, userinfo: user }), do: check_access(String.to_atom(user <> "@" <> host), path)
    defp to_path(%URI{ scheme: "file" }), do: { :error, "only supports local or remote node file references" }
    defp to_path(uri) when is_binary(uri), do: URI.decode(uri) |> URI.parse |> to_path
    defp to_path(_), do: { :error, { :invalid_reference, "not a file reference" } }

    defp check_access(node, path) do
        if Enum.any?(config(:access, []), fn
            { ^node, access } -> include_path?(path, access)
            { _, _ } -> false
            access -> include_path?(path, access)
        end) do
            { :ok, { node, path } }
        else
            { :error, { :invalid_reference, "protected file" } }
        end
    end

    defp extensions(path) do
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

    defp format_posix_error({ :error, :enoent }, path), do: { :error, { :unknown_resource, path } }
    defp format_posix_error({ :error, reason }, _), do: { :error, { :internal, reason } }

    defp match_to_regex(match, regexes \\ { "", "" }, escape \\ false, wildcard \\ nil)
    defp match_to_regex("", { literal, _ }, _, _) do
        IO.iodata_to_binary(["^", literal, "$"])
        |> Regex.compile!
    end
    defp match_to_regex("\\" <> match, regexes, false, wildcard), do: match_to_regex(match, regexes, true, wildcard)
    defp match_to_regex("[!" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\[!"], [special, "[^"] }, false, :character)
    defp match_to_regex("[" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\["], [special, "["] }, false, :character)
    defp match_to_regex("]" <> match, { _, special }, false, :character) do
        special = [special, "]"]
        match_to_regex(match, { special, special }, false, nil)
    end
    defp match_to_regex("-" <> match, { literal, special }, false, :character), do: match_to_regex(match, { [literal, "\\-"], [special, "-"] }, false, :character)
    defp match_to_regex("{" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "\\{"], [special, "("] }, false, :alternation)
    defp match_to_regex("}" <> match, { _, special }, false, :alternation) do
        special = [special, ")"]
        match_to_regex(match, { special, special }, false, nil)
    end
    defp match_to_regex("," <> match, { literal, special }, false, :alternation), do: match_to_regex(match, { [literal, ","], [special, "|"] }, false, :alternation)
    defp match_to_regex("?" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, "."], [special, "."] }, false, nil)
    defp match_to_regex("*" <> match, { literal, special }, false, nil), do: match_to_regex(match, { [literal, ".*"], [special, ".*"] }, false, nil)
    defp match_to_regex(<<c :: utf8, match :: binary>>, { literal, special }, _, wildcard) when c in '.^$*+-?()[]{}|\\' do
        c = <<"\\", c :: utf8>>
        match_to_regex(match, { [literal, c], [special, c] }, false, wildcard)
    end
    defp match_to_regex(<<c :: utf8, match :: binary>>, { literal, special }, _, wildcard) do
        c = <<c :: utf8>>
        match_to_regex(match, { [literal, c], [special, c] }, false, wildcard)
    end

    defp path_match(path, glob, processed \\ false)
    defp path_match([], [], _), do: true
    defp path_match([], ["**"], _), do: true
    defp path_match([], _, _), do: false
    defp path_match([_|path], ["**", "*"|glob], _), do: path_match(path, ["**"|glob], false)
    defp path_match([component|path], ["**", component|glob], _), do: path_match(path, glob, false)
    defp path_match([component|path], ["**", match = %Regex{}|glob], _) do
        if Regex.match?(match, component) do
            path_match(path, glob, false)
        else
            path_match(path, ["**", match|glob], true)
        end
    end
    defp path_match(path, ["**", match|glob], false), do: path_match(path, ["**", match_to_regex(match)|glob], true)
    defp path_match([_|path], glob = ["**"|_], processed), do: path_match(path, glob, processed)
    defp path_match([_|path], ["*"|glob], _), do: path_match(path, glob, false)
    defp path_match([component|path], [component|glob], _), do: path_match(path, glob, false)
    defp path_match([component|path], [match = %Regex{}|glob], _) do
        if Regex.match?(match, component) do
            path_match(path, glob, false)
        else
            false
        end
    end
    defp path_match(path, [match|glob], false), do: path_match(path, [match_to_regex(match)|glob], true)
    defp path_match(_, _, _), do: false

    defp include_path?(path, regex = %Regex{}), do: Regex.match?(regex, path)
    defp include_path?(path, glob) when is_binary(glob), do: path_match(Path.split(path), Path.split(glob))
    defp include_path?(path, fun), do: Callback.call(fun, [path])

    defp config(key, default \\ nil) do
        Application.get_env(:resx, __MODULE__)[key] || default
    end

    @doc false
    def call(node, module, fun, args) do
        case node() do
            ^node -> apply(module, fun, args)
            _ ->
                rpc = config(:rpc, { :rpc, :call, 4 })
                Callback.call(rpc, [node, module, fun, args])
        end
    end

    defp call(node, fun, args) do
        case call(node, __MODULE__, fun, args) do
            result = { type, _ } when type in [:ok, :error] -> result
            reason -> { :error, { :internal, reason } }
        end
    end

    @doc false
    def file_open(repo = { _, path }) do
        with { :read, { :ok, data } } <- { :read, File.read(path) },
             { :stat, timestamp } when is_integer(timestamp) <- { :stat, timestamp(path) } do
                content = %Content{
                    type: extensions(path),
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

                { :ok,  resource }
        else
            { _, error } -> format_posix_error(error, path)
        end
    end

    @doc false
    def file_stream(repo = { node, path }) do
        stream = File.stream!(path)
        case timestamp(path) do
            timestamp when is_integer(timestamp) ->
                content = %Content.Stream{
                    type: extensions(path),
                    data: %__MODULE__.Stream{ stream: stream, node: node }
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

                { :ok,  resource }
            error -> format_posix_error(error, path)
        end
    end

    @doc false
    def file_exists?(path), do: { :ok, File.exists?(path) }

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

    @impl Resx.Producer
    def open(reference) do
        case to_path(reference) do
            { :ok, repo = { node, _ } } -> call(node, :file_open, [repo])
            error -> error
        end
    end

    @impl Resx.Producer
    def stream(reference) do
        case to_path(reference) do
            { :ok, repo = { node, _ } } -> call(node, :file_stream, [repo])
            error -> error
        end
    end

    @impl Resx.Producer
    def exists?(reference) do
        case to_path(reference) do
            { :ok, { node, path } } -> call(node, :file_exists?, [path])
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
            { :ok, { node, path } } -> { :ok, URI.encode("file://" <> to_string(node) <> path) }
            error -> error
        end
    end

    @impl Resx.Producer
    def resource_attributes(reference) do
        case to_path(reference) do
            { :ok, { node, path } } -> call(node, :file_attributes, [path])
            error -> error
        end
    end
end
