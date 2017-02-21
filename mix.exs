defmodule UeberauthGoodreads.Mixfile do
  use Mix.Project

  def project do
    [app: :ueberauth_goodreads,
     version: "0.1.0",
     name: "Ueberauth Goodreads Strategy",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :httpoison, :oauth, :ueberauth]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.11"},
      {:oauth, github: "tim/erlang-oauth"},
      {:poison, "~> 1.3 or ~> 2.0"},
      {:ueberauth, "~> 0.3"},
      {:sweet_xml, "~> 0.6.5"},
      {:credo, "~> 0.6.1", only: [:dev, :test]}
    ]
  end
end
