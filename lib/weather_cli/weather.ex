defmodule WeatherCli.Weather do
  @moduledoc """
  Fetches current weather data from the Open-Meteo Forecast API
  given geographic coordinates.
  """

  @base_url "https://api.open-meteo.com/v1/forecast"

  # WMO Weather interpretation codes → human-readable Portuguese descriptions.
  # Reference: https://open-meteo.com/en/docs (section "WMO Weather interpretation codes")
  @wmo_codes %{
    0 => "Céu limpo",
    1 => "Principalmente limpo",
    2 => "Parcialmente nublado",
    3 => "Nublado",
    45 => "Neblina",
    48 => "Neblina com geada",
    51 => "Garoa leve",
    53 => "Garoa moderada",
    55 => "Garoa intensa",
    61 => "Chuva leve",
    63 => "Chuva moderada",
    65 => "Chuva forte",
    71 => "Neve leve",
    73 => "Neve moderada",
    75 => "Neve forte",
    80 => "Pancadas de chuva leves",
    81 => "Pancadas de chuva moderadas",
    82 => "Pancadas de chuva violentas",
    95 => "Tempestade",
    96 => "Tempestade com granizo leve",
    99 => "Tempestade com granizo forte"
  }

  @doc """
  Fetches current weather for the given latitude and longitude.

  Returns `{:ok, weather_map}` on success or `{:error, reason}` on failure.
  The `weather_map` contains:
  - `:temperature` — current temperature (float)
  - `:feels_like` — apparent temperature (float)
  - `:humidity` — relative humidity percentage (integer)
  - `:wind_speed` — wind speed in km/h (float)
  - `:condition` — human-readable weather description (string)
  - `:unit` — temperature unit string, e.g. "°C" (string)
  """
  @spec fetch(number, number) ::
          {:ok,
           %{
             temperature: float,
             feels_like: float,
             humidity: integer,
             wind_speed: float,
             condition: String.t(),
             unit: String.t()
           }}
          | {:error, String.t()}
  def fetch(lat, lon) when is_number(lat) and is_number(lon) do
    params = [
      latitude: lat,
      longitude: lon,
      current:
        "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code",
      wind_speed_unit: "kmh",
      timezone: "auto"
    ]

    case Req.get(@base_url, params: params) do
      {:ok, %{status: 200, body: %{"current" => current, "current_units" => units}}} ->
        parse_current(current, units)

      {:ok, %{status: 200}} ->
        {:error, "Resposta inesperada da API de clima."}

      {:ok, %{status: status}} ->
        {:error, "Erro na API de clima (HTTP #{status})."}

      {:error, %{reason: :timeout}} ->
        {:error, "A API de clima demorou demais para responder. Tente novamente."}

      {:error, reason} ->
        {:error, "Falha de conexão: #{inspect(reason)}"}
    end
  end

  def fetch(_, _), do: {:error, "Coordenadas geográficas inválidas."}

  @doc """
  Returns a human-readable description for a WMO weather code.
  Falls back to a generic string for unknown or non-integer codes.
  """
  @spec describe_condition(integer | any) :: String.t()
  def describe_condition(code) when is_integer(code) do
    Map.get(@wmo_codes, code, "Condição desconhecida (código #{code})")
  end

  def describe_condition(_), do: "Condição desconhecida"

  # Extracts and validates fields from the "current" block of the API response.
  # Returns {:error, _} if temperature data is missing, since it is the core field.
  defp parse_current(current, units) do
    temperature = current["temperature_2m"]
    feels_like = current["apparent_temperature"]

    if is_number(temperature) and is_number(feels_like) do
      {:ok,
       %{
         temperature: temperature,
         feels_like: feels_like,
         humidity: current["relative_humidity_2m"] || 0,
         wind_speed: current["wind_speed_10m"] || 0.0,
         condition: describe_condition(current["weather_code"]),
         unit: units["temperature_2m"] || "°C"
       }}
    else
      {:error, "Dados de temperatura ausentes na resposta da API."}
    end
  end
end
