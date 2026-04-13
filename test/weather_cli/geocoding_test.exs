defmodule WeatherCli.GeocodingTest do
  use ExUnit.Case, async: true

  alias WeatherCli.Geocoding

  describe "get_coordinates/1 — validação de tipo" do
    test "string vazia retorna erro" do
      assert {:error, msg} = Geocoding.get_coordinates("")
      assert is_binary(msg)
    end

    test "nil retorna erro com mensagem clara" do
      assert {:error, msg} = Geocoding.get_coordinates(nil)
      assert msg =~ "texto"
    end

    test "inteiro retorna erro com mensagem clara" do
      assert {:error, msg} = Geocoding.get_coordinates(123)
      assert msg =~ "texto"
    end

    test "atom retorna erro com mensagem clara" do
      assert {:error, msg} = Geocoding.get_coordinates(:cidade)
      assert msg =~ "texto"
    end

    test "lista retorna erro" do
      assert {:error, _} = Geocoding.get_coordinates(["São Paulo"])
    end
  end

  describe "get_coordinates/1 — integração com API" do
    @tag :integration
    test "cidade válida retorna coordenadas corretas" do
      assert {:ok, location} = Geocoding.get_coordinates("São Paulo")
      assert is_float(location.lat)
      assert is_float(location.lon)
      assert is_binary(location.name)
      assert is_binary(location.country)
      assert location.lat >= -90.0 and location.lat <= 90.0
      assert location.lon >= -180.0 and location.lon <= 180.0
    end

    @tag :integration
    test "country é string mesmo quando ausente na resposta da API" do
      {:ok, location} = Geocoding.get_coordinates("São Paulo")
      assert is_binary(location.country)
    end

    @tag :integration
    test "cidade inexistente retorna {:error, string}" do
      assert {:error, reason} = Geocoding.get_coordinates("xyzxyzxyz_cidade_inexistente_999abc")
      assert is_binary(reason)
      assert reason =~ "não encontrada"
    end

    @tag :integration
    test "entrada de números como string retorna {:error, string}" do
      assert {:error, reason} = Geocoding.get_coordinates("99999")
      assert is_binary(reason)
    end
  end
end
