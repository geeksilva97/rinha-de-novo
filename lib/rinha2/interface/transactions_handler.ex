defmodule Rinha2.Interface.TransactionsHandler do
  def init(req, options) do
    req = :cowboy_req.reply(200, %{
      <<"content-type">> => <<"text/plain">>
    }, <<"Hello world">>, req)

    {:ok, req, options}
  end
end