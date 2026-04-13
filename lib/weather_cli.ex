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
  Exibe o **clima atual** para a cidade informada.
  Se nenhuma cidade for fornecida, solicita via prompt interativo.
  """
  @spec run(String.t() | nil) :: :ok
  def run(city \\ nil), do: WeatherCli.CLI.run(city)

  @doc """
  Exibe a **previsão dos próximos 5 dias** para a cidade informada.
  Se nenhuma cidade for fornecida, solicita via prompt interativo.
  """
  @spec run_forecast(String.t() | nil) :: :ok
  def run_forecast(city \\ nil), do: WeatherCli.CLI.run_forecast(city)
end
