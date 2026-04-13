defmodule Mix.Tasks.Forecast do
  @shortdoc "Exibe a previsão do tempo para os próximos 5 dias"

  @moduledoc """
  Busca e exibe a previsão do tempo diária para os próximos 5 dias
  usando a Open-Meteo API.

  ## Uso

      mix forecast "São Paulo"
      mix forecast London
      mix forecast                  # solicita o nome via prompt interativo

  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [city | _] -> WeatherCli.run_forecast(city)
      [] -> WeatherCli.run_forecast()
    end
  end
end
