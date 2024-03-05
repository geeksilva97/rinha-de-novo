defmodule Rinha2.Client do
  use GenServer

  require Logger

  alias :mnesia, as: Mnesia

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
    Logger.info("start client #{inspect(process_identifier(client_id))} | #{inspect(node())}")

    {:ok, {0, limit, [], :"event_log_client#{client_id}"}}
  end

  def process_events(client_id) do
    Logger.info("Gotta Process events for client #{client_id}")

    GenServer.cast(process_identifier(client_id), {:process_events})
  end

  def credit(client_id, payload) do
    GenServer.call(process_identifier(client_id), {:credit, payload})
  end

  def debit(client_id, payload) do
    GenServer.call(process_identifier(client_id), {:debit, payload})
  end

  def summary(client_id) do
    GenServer.call(process_identifier(client_id), {:summary})
  end

  def handle_call({:credit, payload}, _from, {balance, limit, latest_txns, table}) do
    transaction = payload_to_transaction(payload)

    :ok = Mnesia.dirty_write({table, make_ref(), 1, transaction})

    new_list = case length(latest_txns) >= @amount_txns_to_keep do
      true -> [transaction | latest_txns] |> List.delete_at(-1)
      _ -> [transaction | latest_txns]
    end

    new_balance = balance + transaction["valor"]

    {:reply, {:ok, new_balance, limit}, {new_balance, limit, new_list, table}}
  end

  def handle_call({:debit, payload}, _from, state = {balance, limit, latest_txns, table}) do
    new_balance = balance - payload["valor"]

    case new_balance < limit do
      true ->
        {:reply, {:unprocessable, balance, limit}, state}
      _ -> 
        transaction = payload_to_transaction(payload)

        :ok = Mnesia.dirty_write({table, make_ref(), 1, transaction})

        new_list = case length(latest_txns) >= @amount_txns_to_keep do
          true -> [transaction | latest_txns] |> List.delete_at(-1)
          _ -> [transaction | latest_txns]
        end

        {:reply, {:ok, new_balance, limit}, {new_balance, limit, new_list, table}}
    end
  end

  def handle_call({:summary}, _from, state = {balance, limit, latest_txns, _table}) do
    {:reply, {:ok, balance, limit, latest_txns}, state}
  end

  def handle_cast({:process_events}, state = {_balance, limit, _txns, table}) do
    Logger.info("Processing events for table #{inspect(table)}")

    :yes = Mnesia.force_load_table(table)

    events = Mnesia.dirty_match_object({ table, :_, :_, :_ })

    Logger.info("Events #{inspect(events)}")

    {computed_balance, computed_txns} = events |> Enum.reduce({0, []}, fn {_table_name, _event_id, _event_version, event_payload}, acc = {current_balance, txns} ->
      %{ "valor" => valor, "tipo" => tipo } = event_payload

      new_list = case length(txns) >= @amount_txns_to_keep do
        true -> [event_payload | txns] |> List.delete_at(-1)
        _ -> [event_payload | txns]
      end

      new_balance = case tipo do
        "d" -> current_balance - valor
        "c" -> current_balance + valor
      end

      {new_balance, new_list}
    end)

    Logger.info("computed #{inspect(table)} -- balance #{computed_balance} | txns #{inspect(computed_txns)}")

    {:noreply, { computed_balance, limit, computed_txns, table }}
  end

  defp payload_to_transaction(payload) do
    payload
    |> Map.put(<<"realizada_em">>, "#{DateTime.utc_now()}")
  end

  def process_name(client_id), do: :"client#{client_id}"
  defp process_identifier(client_id), do: {:global, process_name(client_id)}
end
