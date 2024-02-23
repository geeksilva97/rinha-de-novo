defmodule Rinha2.ClientReplica do

  require Logger

  def start_link({client_id, limit}) do
    GenServer.start_link(__MODULE__, {client_id, limit}, name: process_name(client_id))
  end

  @spec init({client_id :: integer(), limit :: integer()}) :: {:ok, {balance :: integer(), limit :: integer(), latest_txns :: list()}}
  def init({client_id, limit}) do
    Logger.info("Starting client replica")
    {:ok, {0, limit, []}}
  end

  def summary(client_id) do
    GenServer.call(process_name(client_id), {:summary})
  end

  def set(client_id, new_state) do
    GenServer.cast(process_name(client_id), {:set, client_id, new_state})
  end

  def handle_cast({:set, client_id, new_state}, current_state) do
    # Logger.info("[#{node()}] - updating replica for client#{client_id}")

    {:noreply, new_state}
  end

  def handle_call({:summary}, _from, state = {balance, limit, latest_txns}) do
    {:reply, {:ok, balance, limit, latest_txns}, state}
  end

  def process_name(client_id), do: :"client_replica#{client_id}"
end
