defmodule Rinha2.Application do
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Rinha2.Worker.start_link(arg)
      # {Rinha2.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rinha2.Supervisor]


    Logger.info("Starting application at node #{node()}")

    Supervisor.start_link(children, opts)
  end
end
