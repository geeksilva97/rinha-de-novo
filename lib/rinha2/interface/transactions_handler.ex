defmodule Rinha2.Interface.TransactionsHandler do
  require Logger

  def init(req, options) do
    method = :cowboy_req.method(req)

    req = handle_req(method, req)

    {:ok, req, options}
  end

  defp handle_req(<<"POST">>, req) do
    {:ok, body, _req} = read_body(req, <<"">>)

    Logger.info("Request body -> #{inspect(body)}")

    case Jason.decode(body) do
      {:ok, payload = %{"tipo" => tipo}} ->
        handle_transaction(tipo, payload, req)
      _ ->
        :cowboy_req.reply(400, req)
    end
  end

  defp handle_transaction("c", payload, req) do
    :cowboy_req.reply(200, %{
      <<"content-type">> => <<"application/json">>
        }, <<"{\"limite\":0,\"saldo\":0}">>, req)
  end

  defp handle_transaction("d", payload, req) do
    :cowboy_req.reply(200, %{
      <<"content-type">> => <<"application/json">>
        }, <<"{\"limite\":0,\"saldo\":0}">>, req)
  end

  defp handle_transaction(_, _, req) do
    :cowboy_req.reply(422, req)
  end

  defp read_body(req, acc) do
    case :cowboy_req.read_body(req) do
      {:ok, data, req} -> {:ok, <<acc::binary, data::binary>>, req}
      {:more, data, req} -> read_body(req, <<acc::binary, data::binary>>)
    end
  end
end
