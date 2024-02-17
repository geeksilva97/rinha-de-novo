defmodule Rinha2.Application do
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task, fn ->
        Logger.info("#{node()} attempting to connect to #{bootstrap_node()}")

        case Node.connect(bootstrap_node()) do
          true ->
            Logger.info("Connection succeeded. We are a cluster")
          _ ->
            Logger.info("Could not connect to #{bootstrap_node()}")
        end
      end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rinha2.Supervisor]


    Logger.info("Starting application at node #{node()}")

    Supervisor.start_link(children, opts)
  end

  def bootstrap_node() do
    System.get_env("BOOTSTRAP_NODE", "fook") |> String.to_atom()
  end
end
