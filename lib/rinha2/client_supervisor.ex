defmodule Rinha2.ClientSupervisor do
  use Supervisor

  require Logger

  alias :mnesia, as: Mnesia

  @client_data [
    {1, -100000},
    {2, -80000},
    {3, -1000000},
    {4, -10000000},
    {5, -500000}]

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def create_tables() do
    nodes = [node() | Node.list()]

    Logger.info("Gotta create the tables :: cluster -> #{inspect(nodes)}")

    @client_data
    |> Enum.map(fn {client_id, limit} -> 
      :ok = case Mnesia.create_table(:"event_log_client#{client_id}", [attributes: [:event_id, :version, :event_data], type: :bag, disc_copies: nodes]) do
        {:atomic, :ok} -> :ok
        {:aborted, {:already_exists, _}} -> :ok
        other -> other
      end
    end)
  end

  def init(_) do
    children = @client_data
      |> Enum.map(fn {client_id, limit} -> 
        %{
          id: Rinha2.Client.process_name(client_id),
          start: {Rinha2.Client, :start_link, [{client_id, limit}]}
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
