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

    opts = [strategy: :one_for_one, name: Rinha2.Supervisor]

    Logger.info("Starting application at node #{node()}")

    start_web_interface()

    Supervisor.start_link(children, opts)
  end

  defp start_web_interface() do
    Logger.info("starting web application")
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/clientes/:client_id/transacoes", Rinha2.Interface.TransactionsHandler, []},
        {"/clientes/:client_id/extrato", Rinha2.Interface.SummaryHandler, []},
      ]}
    ])

    {:ok, _} = :cowboy.start_clear(
      :rinha2_listener,
      [{:port, 8080}],
      %{env: %{dispatch: dispatch}})
  end

  def bootstrap_node() do
    System.get_env("BOOTSTRAP_NODE", "fook") |> String.to_atom()
  end
end
