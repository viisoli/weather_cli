defmodule WeatherCli.CLI do
  @moduledoc """
  Handles user input/output and orchestrates the weather lookup flow.
  """

  alias WeatherCli.{Geocoding, Weather, Formatter}

  @doc """
  Fetches and displays weather for the given city name.
  If no city is provided, prompts the user interactively via stdin.
  """
  @spec run(String.t() | nil) :: :ok
  def run(city \\ nil) do
    city = city || prompt_city()

    city
    |> String.trim()
    |> lookup_and_display()
  end

  defp prompt_city do
    IO.write("\nDigite o nome da cidade: ")
    IO.read(:line)
  end

  defp lookup_and_display("") do
    IO.puts("\n❌ Por favor, informe o nome de uma cidade.")
  end

  defp lookup_and_display(city) do
    case validate_city(city) do
      :ok ->
        IO.puts("\n🔍 Buscando clima para \"#{city}\"...")

        with {:ok, location} <- Geocoding.get_coordinates(city),
             {:ok, weather} <- Weather.fetch(location.lat, location.lon) do
          Formatter.display(location, weather)
        else
          {:error, reason} -> IO.puts("\n❌ #{reason}")
        end

      {:error, reason} ->
        IO.puts("\n❌ #{reason}")
    end
  end

  # Validates the trimmed city string before hitting the API.
  # Uses \p{L} (Unicode letter property) to correctly handle accented characters
  # like ñ, ã, ç, ø — which [:alpha:] misses in PCRE without full Unicode support.
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
