defmodule WeatherCli.Geocoding do
  @moduledoc """
  Resolves a city name into geographic coordinates (latitude/longitude)
  using the Open-Meteo Geocoding API.
  """

  @base_url "https://geocoding-api.open-meteo.com/v1/search"

  @doc """
  Returns `{:ok, %{lat: float, lon: float, name: String.t(), country: String.t()}}`
  or `{:error, reason}` for the given city name.

  The `country` field may be an empty string for locations without a country
  (e.g. disputed territories or open-ocean coordinates).
  """
  @spec get_coordinates(String.t()) ::
          {:ok, %{lat: float, lon: float, name: String.t(), country: String.t()}}
          | {:error, String.t()}
  def get_coordinates(city) when is_binary(city) and city != "" do
    params = [name: city, count: 1, language: "pt", format: "json"]

    case Req.get(@base_url, params: params) do
      {:ok, %{status: 200, body: %{"results" => [result | _]}}} ->
        {:ok,
         %{
           lat: result["latitude"],
           lon: result["longitude"],
           name: result["name"],
           country: result["country"] || ""
         }}

      {:ok, %{status: 200}} ->
        # Covers both empty "results" list and unexpected body shapes
        {:error, "Cidade \"#{city}\" não encontrada. Verifique o nome e tente novamente."}

      {:ok, %{status: status}} ->
        {:error, "Erro na API de geocodificação (HTTP #{status})."}

      {:error, %{reason: :timeout}} ->
        {:error, "A API de geocodificação demorou demais para responder. Tente novamente."}

      {:error, reason} ->
        {:error, "Falha de conexão: #{inspect(reason)}"}
    end
  end

  def get_coordinates(_), do: {:error, "Entrada inválida: o nome da cidade deve ser um texto."}
end
