defmodule Resx.MixProject do
    use Mix.Project

    def project do
        [
            app: :resx,
            description: "Resource management and processing",
            version: "0.1.3",
            elixir: "~> 1.7",
            start_permanent: Mix.env() == :prod,
            deps: deps(),
            dialyzer: [plt_add_deps: :transitive],
            package: package(),
            docs: [
                markdown_processor_options: [extensions: [SimpleMarkdownExtensionSvgBob]]
            ]
        ]
    end

    def application do
        [extra_applications: [:logger]]
    end

    defp deps do
        [
            { :mime, "~> 1.3" },
            { :callback, "~> 0.1.0" },
            { :path_match, "~> 0.1.0" },
            { :ex_doc, "~> 0.18", only: :dev, runtime: false },
            { :simple_markdown, "~> 0.5.4", only: :dev, runtime: false },
            { :ex_doc_simple_markdown, "~> 0.3", only: :dev, runtime: false },
            { :simple_markdown_extension_svgbob, "~> 0.1", only: :dev, runtime: false },
            { :local_cluster, "~> 1.0", only: :test }
        ]
    end

    defp package do
        [
            maintainers: ["Stefan Johnson"],
            licenses: ["BSD 2-Clause"],
            links: %{ "GitHub" => "https://github.com/ScrimpyCat/Resx" }
        ]
    end
end
