defmodule PoemBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :poem_bot,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
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
      {:dep_from_hexpm, "~> 0.3.0"},
      {:jason, "~> 1.3"},
      {:oauther, "~> 1.1"},
      {:extwitter, "~> 0.13"},
      {:exqlite, "~> 0.11.4"}
    ]
  end
end
