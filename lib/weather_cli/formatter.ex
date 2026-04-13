defmodule WeatherCli.Formatter do
  @moduledoc """
  Formats weather data into a human-friendly string for terminal display.
  Handles both current conditions and 5-day forecasts.
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

  # ── Current weather ────────────────────────────────────────────────────────

  @doc "Prints a current weather report to stdout."
  @spec display(location, weather) :: :ok
  def display(location, weather), do: IO.puts(render(location, weather))

  @doc "Returns the current weather report as a string (useful for testing)."
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

  # ── 5-day forecast ─────────────────────────────────────────────────────────

  @doc "Prints a 5-day forecast report to stdout."
  @spec display_forecast(location, WeatherCli.Forecast.t()) :: :ok
  def display_forecast(location, forecast), do: IO.puts(render_forecast(location, forecast))

  @doc "Returns the 5-day forecast report as a string (useful for testing)."
  @spec render_forecast(location, WeatherCli.Forecast.t()) :: String.t()
  def render_forecast(location, %{days: [], unit: _unit}) do
    country_suffix = if location.country != "", do: ", #{location.country}", else: ""

    """

    ╔══════════════════════════════════════╗
    ║      PREVISÃO — PRÓXIMOS 5 DIAS      ║
    ╚══════════════════════════════════════╝

      📍 #{location.name}#{country_suffix}

      (Nenhum dado de previsão disponível.)

    ════════════════════════════════════════
    """
  end

  def render_forecast(location, %{days: days, unit: unit}) do
    country_suffix = if location.country != "", do: ", #{location.country}", else: ""
    today = Date.utc_today()

    header = """

    ╔══════════════════════════════════════╗
    ║      PREVISÃO — PRÓXIMOS 5 DIAS      ║
    ╚══════════════════════════════════════╝

      📍 #{location.name}#{country_suffix}
    """

    day_blocks = Enum.map_join(days, "\n", &render_day(&1, unit, today))

    footer = "\n  ════════════════════════════════════════\n"

    header <> day_blocks <> footer
  end

  # ── Private helpers ────────────────────────────────────────────────────────

  defp render_day(%{date: date} = day, unit, today) do
    label = day_label(date, today)
    date_str = if date, do: format_date(date), else: ""
    bar = rain_bar(day.rain_probability)

    """
      ────────────────────────────────────────
      📅 #{label}  #{date_str}
         ☁️  #{day.condition}
         🌡  Máx #{format_temp(day.temp_max, unit)}  ·  Mín #{format_temp(day.temp_min, unit)}
         🌧  Chuva #{day.rain_probability}% #{bar}  ·  💨 #{format_temp(day.wind_speed_max, " km/h")}
    """
  end

  # Returns a left-padded label so "Hoje", "Amanhã", and weekday names
  # all occupy the same width (7 graphemes) for consistent column alignment.
  defp day_label(nil, _today), do: String.pad_trailing("Dia", 7)

  defp day_label(date, today) do
    label =
      cond do
        date == today -> "Hoje"
        date == Date.add(today, 1) -> "Amanhã"
        true -> weekday_name(Date.day_of_week(date))
      end

    String.pad_trailing(label, 7)
  end

  defp weekday_name(1), do: "Segunda"
  defp weekday_name(2), do: "Terça"
  defp weekday_name(3), do: "Quarta"
  defp weekday_name(4), do: "Quinta"
  defp weekday_name(5), do: "Sexta"
  defp weekday_name(6), do: "Sábado"
  defp weekday_name(7), do: "Domingo"

  # "13 Abr" style date label.
  defp format_date(%Date{day: d, month: m}), do: "#{d} #{month_name(m)}"

  defp month_name(1), do: "Jan"
  defp month_name(2), do: "Fev"
  defp month_name(3), do: "Mar"
  defp month_name(4), do: "Abr"
  defp month_name(5), do: "Mai"
  defp month_name(6), do: "Jun"
  defp month_name(7), do: "Jul"
  defp month_name(8), do: "Ago"
  defp month_name(9), do: "Set"
  defp month_name(10), do: "Out"
  defp month_name(11), do: "Nov"
  defp month_name(12), do: "Dez"

  # Visual rain bar: up to 5 filled blocks out of 5.
  defp rain_bar(probability) when is_integer(probability) do
    filled = round(probability / 20)
    String.duplicate("█", filled) <> String.duplicate("░", 5 - filled)
  end

  defp rain_bar(_), do: "░░░░░"

  defp format_temp(value, unit) when is_number(value) do
    "#{:erlang.float_to_binary(value * 1.0, decimals: 1)}#{unit}"
  end

  defp format_temp(_, _), do: "N/D"
end
