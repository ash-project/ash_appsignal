defmodule AshAppsignal.MixProject do
  use Mix.Project

  @description """
  A drop in Ash.Tracer implementation for Appsignal.
  """

  @version "0.1.0"

  def project do
    [
      app: :ash_appsignal,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      description: @description
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp extras() do
    "documentation/**/*.md"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      title =
        path
        |> Path.basename(".md")
        |> String.split(~r/[-_]/)
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
        |> case do
          "F A Q" ->
            "FAQ"

          other ->
            other
        end

      {String.to_atom(path),
       [
         title: title
       ]}
    end)
  end

  defp groups_for_extras() do
    "documentation/*"
    |> Path.wildcard()
    |> Enum.map(fn folder ->
      name =
        folder
        |> Path.basename()
        |> String.split(~r/[-_]/)
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")

      {name, folder |> Path.join("**") |> Path.wildcard()}
    end)
  end

  defp docs do
    [
      main: "AshGraphql",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extra_section: "GUIDES",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: [
        AshAppsignal: [
          AshAppsignal
        ],
        Internals: ~r/.*/
      ]
    ]
  end

  defp package do
    [
      name: :ash_appsignal,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
      CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_appsignal"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ash_version(">= 2.14.14")},
      {:appsignal, "~> 2.0"},
      {:ex_doc, "~> 0.22", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.12", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.5", only: [:dev, :test]},
      {:excoveralls, "~> 0.13", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash"]
      "main" -> [git: "https://github.com/ash-project/ash.git"]
      version -> "~> #{version}"
    end
  end
end
