defmodule Rinha2.Interface.TransactionsHandler do
  def init(req, options) do
    method = :cowboy_req.method(req)

    req = handle_req(method, req)

    {:ok, req, options}
  end

  defp handle_req(<<"POST">>, req) do
    {:ok, body, _req} = read_body(req, <<"">>)

    client_id = :cowboy_req.binding(:client_id, req, <<"0">>) |> :erlang.binary_to_integer()

    case client_validations(client_id) do
      :valid ->
        case Jason.decode(body) do
          {:ok, payload = %{"tipo" => tipo}} ->
            validate_payload(payload, :handle_transaction, [tipo, payload |> Map.put("client_id", client_id), req], req)
          _ ->
            :cowboy_req.reply(422, req)
        end

      _ ->
        :cowboy_req.reply(404, req)
    end
  end

  defp validate_payload(payload, fun, args, req) do
    valor = payload["valor"] || 0
    size_descricao = (payload["descricao"] || "") |> String.length()

    if not is_float(valor) and valor > 0 and size_descricao > 0 and size_descricao < 11 do
      apply(__MODULE__, fun, args)
    else
      :cowboy_req.reply(422, req)
    end
  end

  defp client_validations(client_id) do
    case client_id > 0 and client_id < 6 do
      true ->
        :valid
      _ ->
        :invalid
    end
  end

  def handle_transaction("c", payload, req) do
    {:ok, balance, limit} = Rinha2.Client.credit(payload["client_id"], payload)

    :cowboy_req.reply(200, %{
      <<"content-type">> => <<"application/json">>
        }, <<"{\"limite\":#{-1*limit},\"saldo\":#{balance}}">>, req)
  end

  def handle_transaction("d", payload, req) do

      case Rinha2.Client.debit(payload["client_id"], payload) do
        {:ok, balance, limit} ->
          :cowboy_req.reply(200, %{
            <<"content-type">> => <<"application/json">>
        }, <<"{\"limite\":#{-1*limit},\"saldo\":#{balance}}">>, req)

        {:unprocessable, _, _} ->
          :cowboy_req.reply(422, req)
      end

  end

  def handle_transaction(_, _, req) do
    :cowboy_req.reply(422, req)
  end

  defp read_body(req, acc) do
    case :cowboy_req.read_body(req) do
      {:ok, data, req} -> {:ok, <<acc::binary, data::binary>>, req}
      {:more, data, req} -> read_body(req, <<acc::binary, data::binary>>)
    end
  end
end
