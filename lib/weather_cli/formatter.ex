defmodule WeatherCli.Formatter do
  @moduledoc """
  Formats weather data into a human-friendly string for terminal display.
  """

  @typedoc "Geographic location resolved from the Geocoding API."
  @type location :: %{name: String.t(), country: String.t()}

  @typedoc "Current weather data resolved from the Forecast API."
  @type weather :: %{
          temperature: number | nil,
          feels_like: number | nil,
          humidity: integer,
          wind_speed: number,
          condition: String.t(),
          unit: String.t()
        }

  @doc "Prints a formatted weather report to stdout."
  @spec display(location, weather) :: :ok
  def display(location, weather) do
    IO.puts(render(location, weather))
  end

  @doc "Returns the formatted weather report as a string (useful for testing)."
  @spec render(location, weather) :: String.t()
  def render(location, weather) do
    country_suffix = if location.country != "", do: ", #{location.country}", else: ""

    """

    ╔══════════════════════════════════════╗
    ║         PREVISÃO DO TEMPO            ║
    ╚══════════════════════════════════════╝

      📍 #{location.name}#{country_suffix}
      ☁️  #{weather.condition}

      🌡  Temperatura:    #{format_temp(weather.temperature, weather.unit)}
      🤔 Sensação:       #{format_temp(weather.feels_like, weather.unit)}
      💧 Umidade:        #{weather.humidity}%
      💨 Vento:          #{weather.wind_speed} km/h

    ════════════════════════════════════════
    """
  end

  defp format_temp(value, unit) when is_number(value) do
    "#{:erlang.float_to_binary(value * 1.0, decimals: 1)}#{unit}"
  end

  defp format_temp(_, _), do: "N/D"
end
