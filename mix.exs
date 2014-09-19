defmodule OnionRpc.Mixfile do
  use Mix.Project

  def project do
    [app: :onion_rpc,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :onion_common]]
  end

  defp deps do
    [
      {:onion_common, github: "SkAZi/onion-common"},
    ]
  end
end
