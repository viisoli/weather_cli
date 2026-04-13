# Script: consulta temperatura atual via Open-Meteo (geocoding + forecast).
#
# Uso (na pasta do projeto, com dependências instaladas):
#   mix deps.get
#   mix run scripts/clima.exs São Paulo
#
# Com `mix run ... --` o argv pode vir como ["--", "cidade"]; tratamos os dois casos.

defmodule Clima do
  @geocoding "https://geocoding-api.open-meteo.com/v1/search"
  @forecast "https://api.open-meteo.com/v1/forecast"

  def run do
    city = city_from_argv()

    if city == "" do
      IO.puts(:stderr, "Uso: mix run scripts/clima.exs <nome da cidade>")
      System.halt(1)
    end

    with {:ok, lat, lon, label} <- geocode(city),
         {:ok, temp, unit} <- current_temperature(lat, lon) do
      IO.puts("Temperatura em #{label}: #{temp}#{unit}")
    else
      {:error, :not_found} ->
        IO.puts(:stderr, "Cidade não encontrada: #{city}")
        System.halt(2)

      {:error, reason} ->
        IO.puts(:stderr, "Erro: #{inspect(reason)}")
        System.halt(3)
    end
  end

  defp city_from_argv do
    args =
      case System.argv() do
        ["--" | rest] -> rest
        other -> other
      end

    args |> Enum.join(" ") |> String.trim()
  end

  defp geocode(name) do
    query = URI.encode_query(%{"name" => name, "count" => "1"})
    url = @geocoding <> "?" <> query

    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: %{"results" => [%{} = first | _]}}} ->
        label = [first["name"], first["country"]] |> Enum.reject(&is_nil/1) |> Enum.join(", ")
        {:ok, first["latitude"], first["longitude"], label}

      {:ok, %{status: 200, body: %{"results" => []}}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        {:error, {:http, status}}

      {:error, e} ->
        {:error, e}
    end
  end

  defp current_temperature(lat, lon) do
    query =
      URI.encode_query(%{
        "latitude" => to_string(lat),
        "longitude" => to_string(lon),
        "current" => "temperature_2m",
        "timezone" => "auto"
      })

    url = @forecast <> "?" <> query

    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        temp = get_in(body, ["current", "temperature_2m"])
        unit = get_in(body, ["current_units", "temperature_2m"]) || "°C"

        if is_number(temp) do
          {:ok, temp, unit}
        else
          {:error, :no_temperature}
        end

      {:ok, %{status: status}} ->
        {:error, {:http, status}}

      {:error, e} ->
        {:error, e}
    end
  end
end

Clima.run()
