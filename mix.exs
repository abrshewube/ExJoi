defmodule ExJoi.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/abrshewube/ExJoi"

  def project do
    [
      app: :exjoi,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A Joi-inspired validation library for Elixir",
      package: package(),
      docs: [
        main: "ExJoi",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
