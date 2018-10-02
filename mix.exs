defmodule Resx.MixProject do
    use Mix.Project

    def project do
        [
            app: :resx,
            version: "0.1.0",
            elixir: "~> 1.7",
            start_permanent: Mix.env() == :prod,
            deps: deps()
        ]
    end

    def application do
        [extra_applications: [:logger]]
    end

    defp deps do
        [
            { :mime, "~> 1.3" },
            { :ex_doc, "~> 0.18", only: :dev, runtime: false }
        ]
    end
end
