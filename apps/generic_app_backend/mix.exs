defmodule GenericAppBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :generic_app_backend,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :guardian, :kv],
      mod: {GenericAppBackend.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.3"},
      {:kv, in_umbrella: true},
      {:rename, "~> 0.1.0", only: :dev},
      {:safetybox, "~> 0.1.2" },
      {:guardian, "~> 2.0"},
      {:httpoison, "~> 2.0"}
    ]
  end
end
