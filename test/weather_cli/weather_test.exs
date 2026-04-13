defmodule WeatherCli.WeatherTest do
  use ExUnit.Case, async: true

  alias WeatherCli.Weather

  describe "describe_condition/1" do
    test "código 0 → céu limpo" do
      assert Weather.describe_condition(0) == "Céu limpo"
    end

    test "código 61 → chuva leve" do
      assert Weather.describe_condition(61) == "Chuva leve"
    end

    test "código 95 → tempestade" do
      assert Weather.describe_condition(95) == "Tempestade"
    end

    test "código desconhecido → fallback com o número" do
      assert Weather.describe_condition(999) =~ "999"
    end

    test "nil → fallback genérico" do
      assert Weather.describe_condition(nil) == "Condição desconhecida"
    end

    test "string → fallback genérico" do
      assert Weather.describe_condition("sunny") == "Condição desconhecida"
    end

    test "códigos de garoa/chuva congelante estão mapeados" do
      assert Weather.describe_condition(56) =~ "congelante"
      assert Weather.describe_condition(57) =~ "congelante"
      assert Weather.describe_condition(66) =~ "congelante"
      assert Weather.describe_condition(67) =~ "congelante"
    end

    test "código 77 → grãos de neve" do
      assert Weather.describe_condition(77) == "Grãos de neve"
    end

    test "códigos de pancadas de neve estão mapeados" do
      assert Weather.describe_condition(85) =~ "neve"
      assert Weather.describe_condition(86) =~ "neve"
    end
  end

  describe "fetch/2 — validação de argumentos" do
    test "nil, nil → {:error, string}" do
      assert {:error, msg} = Weather.fetch(nil, nil)
      assert is_binary(msg)
    end

    test "strings de coordenadas → {:error, string}" do
      assert {:error, msg} = Weather.fetch("-23.5", "-46.6")
      assert is_binary(msg)
    end

    test "atoms → {:error, string}" do
      assert {:error, msg} = Weather.fetch(:lat, :lon)
      assert is_binary(msg)
    end
  end

  describe "fetch/2 — integração com API" do
    @tag :integration
    test "retorna estrutura completa e tipada para São Paulo" do
      assert {:ok, weather} = Weather.fetch(-23.5505, -46.6333)
      assert is_number(weather.temperature)
      assert is_number(weather.feels_like)
      assert is_integer(weather.humidity)
      assert weather.humidity in 0..100
      assert is_number(weather.wind_speed)
      assert weather.wind_speed >= 0
      assert is_binary(weather.condition)
      assert is_binary(weather.unit)
    end

    @tag :integration
    test "nunca levanta exceção para qualquer coordenada numérica" do
      result = Weather.fetch(0.0, 0.0)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
