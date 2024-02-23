defmodule Rinha2.Interface.SummaryHandler do
  require Logger

  def init(req, options) do
    method = :cowboy_req.method(req)

    req = handle_req(method, req)

    {:ok, req, options}
  end

  def handle_req(<<"GET">>, req) do
    client_id = :cowboy_req.binding(:client_id, req, <<"0">>) |> :erlang.binary_to_integer()

    case client_id > 0 and client_id < 6 do
      true ->
        # {:ok, balance, limit, latest_txns} = Rinha2.Client.summary(client_id)
        {:ok, balance, limit, latest_txns} = Rinha2.ClientReplica.summary(client_id)

        encoded_result = :jiffy.encode(%{
          <<"ultimas_transacoes">> => latest_txns,
          <<"saldo">> => %{
            <<"total">> => balance,
            <<"limite">> => -1*limit,
            <<"data_extrato">> => <<"#{DateTime.utc_now()}">>
          }
        })

        :cowboy_req.reply(200, %{
          <<"content-type">> => <<"application/json">>
        }, encoded_result, req)
      false ->
        :cowboy_req.reply(404, req)
    end
  end
end
