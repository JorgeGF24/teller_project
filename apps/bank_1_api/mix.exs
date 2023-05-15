defmodule Bank1API.MixProject do
  use Mix.Project

  def project do
    [
      app: :bank_1_api,
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
      extra_applications: [:logger, :kv, :guardian],
      mod: {Bank1API.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:guardian, "~> 2.0"},
      {:kv, in_umbrella: true},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.3"},
      {:safetybox, "~> 0.1.2" },
      {:ecto, "~> 3.10"}
    ]
  end
end
