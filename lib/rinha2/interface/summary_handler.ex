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
        :cowboy_req.reply(204, req)
      false ->
        :cowboy_req.reply(404, req)
    end
  end
end
