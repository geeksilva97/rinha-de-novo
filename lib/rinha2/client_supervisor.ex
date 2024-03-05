defmodule Rinha2.ClientSupervisor do
  use Supervisor

  require Logger

  def start_link(_init_arg) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      {1, -100000},
      {2, -80000},
      {3, -1000000},
      {4, -10000000},
      {5, -500000}]
      |> Enum.map(fn {client_id, limit} -> 
        %{
          id: Rinha2.Client.process_name(client_id),
          start: {Rinha2.Client, :start_link, [{client_id, limit}]}
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
