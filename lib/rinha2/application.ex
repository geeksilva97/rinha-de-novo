defmodule Rinha2.Application do
  @moduledoc false

  require Logger

  alias :mnesia, as: Mnesia

  use Application

  def create_schemas() do
    Logger.info("creating schemas in cluster -- #{inspect([node() | Node.list()])}")

    :rpc.multicall(:mnesia, :stop, [])

    :ok = case Mnesia.create_schema([node() | Node.list()]) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      other -> other
    end

    :rpc.multicall(:mnesia, :start, [])

    Rinha2.ClientSupervisor.create_tables()
  end

  @impl true
  def start(_type, _args) do
    folder_name = node() |> Atom.to_charlist()
    Application.put_env(:mnesia, :dir, '/app/mnesia-data/#{folder_name}')

    children = [
      {Task, fn ->
        Logger.info("#{node()} attempting to connect to #{bootstrap_node()}")
        node_type = System.get_env("NODE_TYPE", nil)

        case Node.connect(bootstrap_node()) do
          true ->
            Logger.info("Connection succeeded. We are a cluster :: node type -> #{node_type}")

            if node_type == "master" do
              create_schemas()
              Mnesia.info()

              1..5 |> Enum.map(fn client_id -> 
                Rinha2.Client.process_events(client_id)
              end)
            end

          _ ->
            if node_type == "master" do
              Logger.error("Could not connect to #{bootstrap_node()}")

              System.stop(1)
            end
        end
      end},
        Rinha2.ClientSupervisor
    ]

    opts = [strategy: :one_for_one, name: Rinha2.Supervisor]

    Logger.info("Starting application at node #{node()}")

    start_web_interface()

    Supervisor.start_link(children, opts)
  end

  defp start_web_interface() do
    Logger.info("starting web interface")
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/clientes/:client_id/transacoes", Rinha2.Interface.TransactionsHandler, []},
        {"/clientes/:client_id/extrato", Rinha2.Interface.SummaryHandler, []},
        {"/info", Rinha2.Interface.InfoHandler, []},
      ]}
    ])

    {:ok, _} = :cowboy.start_clear(
      :rinha2_listener,
      [{:port, 8080}, {:num_acceptors, 350}, {:max_connections, 500}],
      %{env: %{dispatch: dispatch}})
  end

  def bootstrap_node() do
    System.get_env("BOOTSTRAP_NODE", "fook") |> String.to_atom()
  end
end
