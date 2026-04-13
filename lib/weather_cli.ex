defmodule WeatherCli do
  @moduledoc """
  WeatherCli — consulta a temperatura atual de qualquer cidade do mundo.

  Utiliza a Open-Meteo Geocoding API para resolver o nome da cidade
  e a Open-Meteo Forecast API para obter os dados meteorológicos.

  ## Uso via Mix Task

      mix weather "São Paulo"
      mix weather

  ## Uso programático

      WeatherCli.run("Lisboa")
  """

  @doc """
  Ponto de entrada principal. Aceita um nome de cidade como argumento opcional.
  Se não for fornecido, solicita ao usuário via prompt interativo.
  """
  @spec run(String.t() | nil) :: :ok
  def run(city \\ nil), do: WeatherCli.CLI.run(city)
end
