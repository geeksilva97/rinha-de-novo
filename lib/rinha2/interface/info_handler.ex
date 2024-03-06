defmodule Rinha2.Interface.InfoHandler do
  require Logger

  def init(req, options) do
    method = :cowboy_req.method(req)

    req = handle_req(method, req)

    {:ok, req, options}
  end

  def handle_req(<<"GET">>, req) do
    client_id = :cowboy_req.binding(:client_id, req, <<"0">>) |> :erlang.binary_to_integer()

    :mnesia.info()

    :cowboy_req.reply(200, req)
  end
end
