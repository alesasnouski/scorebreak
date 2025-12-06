defmodule Scorebreak.MixProject do
  use Mix.Project

  def project do
    [
      app: :scorebreak,
      version: "0.1.0",
      elixir: "~> 1.19",
      aliases: aliases(),
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
      {:db_connection, "~> 2.8"},
      {:dotenvy, "~> 1.1"},
      {:ecto_ltree, "~> 0.4.0"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.21.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ]
    ]
  end
end
