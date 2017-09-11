defmodule Jibe.Mixfile do
  use Mix.Project

  def project do
    [
      app: :jibe,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      source_url: "https://github.com/jdl/jibe",
      deps: deps()
    ]
  end

  defp package() do
    [
      name: "jibe",
      maintainers: ["jdl"],
      licences: ["MIT"],
      links: %{"GitHub" => "https://github.com/jdl/jibe"}
    ]
  end
  
  defp description() do
   "Functions for checking if a nested map/list matches a particular pattern."
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [ ]
  end
end
