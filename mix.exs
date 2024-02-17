defmodule Rinha2.MixProject do
  use Mix.Project

  def project do
    [
      app: :rinha2,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Rinha2.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.11.0"},
      {:jiffy, "~> 1.1.1"},
      # {:jiffy, git: "https://github.com/davisp/jiffy.git", tags: "1.1.1"}
    ]
  end
end
