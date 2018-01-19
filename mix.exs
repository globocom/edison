defmodule Edison.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :edison,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def elixirc_paths(:test), do: ~w[lib test/support]
  def elixirc_paths(_), do: ~w[lib]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fuse, "~> 2.4"},
    ]
  end
end
