defmodule WeatherCli.CLI do
  @moduledoc """
  Handles user input/output and orchestrates the weather lookup flow.
  """

  alias WeatherCli.{Cache, Geocoding, Weather, Forecast, Formatter}

  # Forecast results use a namespaced key so they never collide with weather entries.
  @forecast_key_prefix "forecast:"

  @doc """
  Fetches and displays **current** weather for the given city name.
  If no city is provided, prompts the user interactively via stdin.
  Results are cached for 1 hour to avoid redundant API calls.
  """
  @spec run(String.t() | nil) :: :ok
  def run(city \\ nil) do
    city = city || prompt_city()
    city |> String.trim() |> run_current()
  end

  @doc """
  Fetches and displays a **5-day forecast** for the given city name.
  If no city is provided, prompts the user interactively via stdin.
  Results are cached for 1 hour to avoid redundant API calls.
  """
  @spec run_forecast(String.t() | nil) :: :ok
  def run_forecast(city \\ nil) do
    city = city || prompt_city()
    city |> String.trim() |> run_5day()
  end

  # ── Private: entry points after trimming ───────────────────────────────────

  defp run_current(""), do: error("Por favor, informe o nome de uma cidade.")
  defp run_current(city) do
    with :ok <- validate_city(city) do
      fetch_current(city)
    else
      {:error, reason} -> error(reason)
    end
  end

  defp run_5day(""), do: error("Por favor, informe o nome de uma cidade.")
  defp run_5day(city) do
    with :ok <- validate_city(city) do
      fetch_forecast(city)
    else
      {:error, reason} -> error(reason)
    end
  end

  # ── Private: current weather ───────────────────────────────────────────────

  defp fetch_current(city) do
    key = Cache.cache_key(city)

    case Cache.get(key) do
      {:ok, {location, weather}} ->
        IO.puts("\n📦 Resultado em cache para \"#{city}\".")
        Formatter.display(location, weather)

      :miss ->
        IO.puts("\n🔍 Buscando clima para \"#{city}\"...")

        with {:ok, location} <- Geocoding.get_coordinates(city),
             {:ok, weather} <- Weather.fetch(location.lat, location.lon) do
          Cache.put(key, {location, weather})
          Formatter.display(location, weather)
        else
          {:error, reason} -> handle_error_with_stale(reason, key, :weather)
        end
    end
  end

  # ── Private: 5-day forecast ────────────────────────────────────────────────

  defp fetch_forecast(city) do
    key = @forecast_key_prefix <> Cache.cache_key(city)

    case Cache.get(key) do
      {:ok, {location, forecast}} ->
        IO.puts("\n📦 Previsão em cache para \"#{city}\".")
        Formatter.display_forecast(location, forecast)

      :miss ->
        IO.puts("\n🔍 Buscando previsão para \"#{city}\"...")

        with {:ok, location} <- Geocoding.get_coordinates(city),
             {:ok, forecast} <- Forecast.fetch(location.lat, location.lon) do
          Cache.put(key, {location, forecast})
          Formatter.display_forecast(location, forecast)
        else
          {:error, reason} -> handle_error_with_stale(reason, key, :forecast)
        end
    end
  end

  # ── Private: error handling ────────────────────────────────────────────────

  # When any API call fails, check if there is stale cached data for this city.
  # If so, display it with an age warning so the user still gets useful information
  # when offline. The `kind` atom determines how to display the stale value.
  defp handle_error_with_stale(reason, key, kind) do
    case Cache.get_stale(key) do
      {:ok, {location, data}, age_seconds} ->
        IO.puts("\n⚠️  #{reason}")
        IO.puts("📦 Exibindo último dado disponível (#{Cache.format_age(age_seconds)} atrás):")
        display_stale(kind, location, data)

      :miss ->
        error(reason)
    end
  end

  defp display_stale(:weather, location, weather), do: Formatter.display(location, weather)
  defp display_stale(:forecast, location, forecast), do: Formatter.display_forecast(location, forecast)

  # ── Private: I/O helpers ───────────────────────────────────────────────────

  defp prompt_city do
    IO.write("\nDigite o nome da cidade: ")
    IO.read(:line)
  end

  defp error(reason), do: IO.puts("\n❌ #{reason}")

  # ── Private: input validation ──────────────────────────────────────────────

  # Uses \p{L} (Unicode letter property) so accented city names like
  # "Ñoño" or "東京" are accepted — [:alpha:] only covers ASCII.
  defp validate_city(city) do
    cond do
      String.match?(city, ~r/^\d+([.,]\d+)?$/) ->
        {:error, "\"#{city}\" parece ser um número. Digite o nome de uma cidade, ex: São Paulo."}

      String.length(city) < 2 ->
        {:error, "O nome da cidade deve ter pelo menos 2 caracteres."}

      String.length(city) > 100 ->
        {:error, "O nome da cidade é longo demais (máximo 100 caracteres)."}

      String.match?(city, ~r/^[^\p{L}]+$/u) ->
        {:error, "\"#{city}\" não parece ser um nome de cidade válido. Use apenas letras e espaços."}

      true ->
        :ok
    end
  end
end
