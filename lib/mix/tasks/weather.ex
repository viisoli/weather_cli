defmodule Mix.Tasks.Weather do
  @shortdoc "Consulta a temperatura atual de uma cidade"

  @moduledoc """
  Busca e exibe a temperatura atual de uma cidade usando a Open-Meteo API.

  ## Uso

      mix weather "São Paulo"
      mix weather London
      mix weather                   # solicita o nome via prompt interativo

  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [city | _] -> WeatherCli.run(city)
      [] -> WeatherCli.run()
    end
  end
end
