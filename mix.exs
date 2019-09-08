defmodule Jibe.Mixfile do
  use Mix.Project

  @github "https://github.com/jdl/jibe"

  def project do
    [
      app: :jibe,
      version: "0.2.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      licences: ["MIT"],
      links: %{"github" => @github},
      source_url: @github,
      deps: deps(),
      docs: docs()
    ]
  end

  defp package() do
    [
      name: "jibe",
      maintainers: ["jdl"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jdl/jibe"}
    ]
  end

  defp description() do
   "Test tool for checking if a nested map/list matches a particular pattern."
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:decimal, "~> 1.8"},
      {:ex_doc, "~>0.21", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Jibe",
      source_url: @github,
      extras: ["README.md"]
    ]
  end
end
