defmodule WeatherCli.Forecast do
  @moduledoc """
  Fetches a 5-day daily weather forecast from the Open-Meteo Forecast API.

  Each day in the result contains:
  - `:date`             — `Date` struct
  - `:temp_max`         — maximum temperature (float)
  - `:temp_min`         — minimum temperature (float)
  - `:condition`        — human-readable weather description (string)
  - `:rain_probability` — max precipitation probability in % (integer)
  - `:wind_speed_max`   — maximum wind speed in km/h (float)
  """

  alias WeatherCli.Weather

  @base_url "https://api.open-meteo.com/v1/forecast"
  @forecast_days 5
  @daily_fields ~w[
    temperature_2m_max
    temperature_2m_min
    weather_code
    precipitation_probability_max
    wind_speed_10m_max
  ]

  @typedoc "A single day's forecast."
  @type day :: %{
          date: Date.t(),
          temp_max: float,
          temp_min: float,
          condition: String.t(),
          rain_probability: integer,
          wind_speed_max: float
        }

  @typedoc "Full 5-day forecast result."
  @type t :: %{days: [day], unit: String.t()}

  @doc """
  Returns `{:ok, %{days: [day], unit: String.t()}}` for the given coordinates,
  or `{:error, reason}`.
  """
  @spec fetch(number, number) :: {:ok, t} | {:error, String.t()}
  def fetch(lat, lon) when is_number(lat) and is_number(lon) do
    params = [
      latitude: lat,
      longitude: lon,
      daily: Enum.join(@daily_fields, ","),
      wind_speed_unit: "kmh",
      timezone: "auto",
      forecast_days: @forecast_days
    ]

    case Req.get(@base_url, params: params) do
      {:ok, %{status: 200, body: %{"daily" => daily, "daily_units" => units}}} ->
        parse_daily(daily, units)

      {:ok, %{status: 200}} ->
        {:error, "Resposta inesperada da API de previsão."}

      {:ok, %{status: status}} ->
        {:error, "Erro na API de previsão (HTTP #{status})."}

      {:error, %{reason: :timeout}} ->
        {:error, "A API de previsão demorou demais para responder. Tente novamente."}

      {:error, reason} ->
        {:error, "Falha de conexão: #{inspect(reason)}"}
    end
  end

  def fetch(_, _), do: {:error, "Coordenadas geográficas inválidas."}

  # Zips all parallel lists from the API into a list of day maps.
  defp parse_daily(daily, units) do
    dates = daily["time"] || []
    temp_max = daily["temperature_2m_max"] || []
    temp_min = daily["temperature_2m_min"] || []
    codes = daily["weather_code"] || []
    rain = daily["precipitation_probability_max"] || []
    wind = daily["wind_speed_10m_max"] || []

    days =
      [dates, temp_max, temp_min, codes, rain, wind]
      |> Enum.zip()
      |> Enum.map(fn {date_str, tmax, tmin, code, rain_pct, wind_spd} ->
        %{
          date: parse_date(date_str),
          temp_max: tmax,
          temp_min: tmin,
          condition: Weather.describe_condition(code),
          rain_probability: rain_pct || 0,
          wind_speed_max: wind_spd || 0.0
        }
      end)

    {:ok, %{days: days, unit: units["temperature_2m_max"] || "°C"}}
  end

  defp parse_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_), do: nil
end
