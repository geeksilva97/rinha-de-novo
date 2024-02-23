defmodule Rinha2.Interface.TransactionsHandler do
  def init(req, options) do
    method = :cowboy_req.method(req)

    # :eprof.start()
    # :eprof.start_profiling([self()])

    req = handle_req(method, req)

    # :eprof.stop_profiling()
    # :eprof.analyze()

    {:ok, req, options}
  end

  defp handle_req(<<"POST">>, req) do
    client_id = :cowboy_req.binding(:client_id, req, <<"0">>) |> :erlang.binary_to_integer()

    case client_validations(client_id) do
      :valid ->
        {:ok, body, _req} = read_body(req, <<"">>)

        try do
          payload = :jiffy.decode(body, [:return_maps])

          validate_payload(payload, :handle_transaction, [payload["tipo"], payload |> Map.put("client_id", client_id), req], req)
        rescue
          _e ->
            :cowboy_req.reply(422, req)
        end

      _ ->
        :cowboy_req.reply(404, req)
    end
  end

  defp validate_payload(payload, fun, args, req) do
    valor = payload["valor"] || 0
    size_descricao = (payload["descricao"] || "") |> String.length()

    unless is_float(valor) or valor <= 0 or size_descricao == 0 or size_descricao > 10 do
      apply(__MODULE__, fun, args)
    else
      :cowboy_req.reply(422, req)
    end
  end

  defp client_validations(client_id) do
    case client_id in 1..5 do
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
