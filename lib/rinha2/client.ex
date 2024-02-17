defmodule Rinha2.Client do
  use GenServer

  @amount_txns_to_keep 10

  def start_link({client_id, limit}) do
    case GenServer.start_link(__MODULE__, {client_id, limit}, name: {:global, process_name(client_id)}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  @spec init({client_id :: integer(), limit :: integer()}) :: {:ok, {balance :: integer(), limit :: integer(), latest_txns :: list()}}
  def init({client_id, limit}) do
    {:ok, {0, limit, []}}
  end

  def credit(client_id, payload) do
    GenServer.call(process_identifier(client_id), {:credit, client_id, payload})
  end

  def debit(client_id, payload) do
    GenServer.call(process_identifier(client_id), {:debit, client_id, payload})
  end

  def summary(client_id) do
    GenServer.call(process_identifier(client_id), {:summary, client_id})
  end

  def handle_call({:credit, client_id, payload}, _from, state = {balance, limit, latest_txns}) do
    transaction = payload_to_transaction(payload)

    new_list = case length(latest_txns) >= @amount_txns_to_keep do
      true -> [transaction | latest_txns] |> List.delete_at(-1)
      _ -> [transaction | latest_txns]
    end

    new_balance = balance + transaction["valor"]

    {:reply, {:ok, new_balance, limit}, {new_balance, limit, new_list}}
  end

  def handle_call({:debit, client_id, payload}, _from, state = {balance, limit, latest_txns}) do
    new_balance = balance - payload["valor"]

    case new_balance < limit do
      true ->
        {:reply, {:unprocessable, balance, limit}, state}
      _ -> 
        transaction = payload_to_transaction(payload)
        new_list = case length(latest_txns) >= @amount_txns_to_keep do
          true -> [transaction | latest_txns] |> List.delete_at(-1)
          _ -> [transaction | latest_txns]
        end

        {:reply, {:ok, new_balance, limit}, {new_balance, limit, new_list}}
    end
  end

  defp payload_to_transaction(payload) do
    Map.delete(payload, "client_id")
    |> Map.put("realizada_em", DateTime.utc_now())
  end

  def process_name(client_id), do: :"client#{client_id}"
  defp process_identifier(client_id), do: {:global, process_name(client_id)}
end
