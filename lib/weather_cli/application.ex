defmodule WeatherCli.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Req automatically starts and registers its own Finch pool (Req.Finch)
    # when the :req application starts. We do not need to start Finch here.
    children = []

    opts = [strategy: :one_for_one, name: WeatherCli.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
