defmodule WeatherCli.FormatterTest do
  use ExUnit.Case, async: true

  alias WeatherCli.Formatter

  @location %{name: "São Paulo", country: "Brasil"}
  @weather %{
    temperature: 22.5,
    feels_like: 21.0,
    humidity: 78,
    wind_speed: 15.3,
    condition: "Parcialmente nublado",
    unit: "°C"
  }

  describe "render/2 — conteúdo esperado" do
    test "inclui nome da cidade" do
      assert Formatter.render(@location, @weather) =~ "São Paulo"
    end

    test "inclui o país" do
      assert Formatter.render(@location, @weather) =~ "Brasil"
    end

    test "inclui temperatura formatada com 1 decimal" do
      assert Formatter.render(@location, @weather) =~ "22.5°C"
    end

    test "inclui sensação térmica" do
      assert Formatter.render(@location, @weather) =~ "21.0°C"
    end

    test "inclui umidade com %" do
      assert Formatter.render(@location, @weather) =~ "78%"
    end

    test "inclui velocidade do vento" do
      assert Formatter.render(@location, @weather) =~ "15.3 km/h"
    end

    test "inclui condição climática" do
      assert Formatter.render(@location, @weather) =~ "Parcialmente nublado"
    end

    test "temperatura inteira exibe .0" do
      assert Formatter.render(@location, %{@weather | temperature: 20.0}) =~ "20.0°C"
    end

    test "retorna string" do
      assert is_binary(Formatter.render(@location, @weather))
    end
  end

  describe "render/2 — country vazio ou nil (territórios sem país)" do
    test "omite vírgula quando country é string vazia" do
      location = %{name: "Ilha", country: ""}
      output = Formatter.render(location, @weather)
      assert output =~ "Ilha"
      refute output =~ "Ilha,"
    end
  end

  describe "render/2 — campos de temperatura nil (dado ausente na API)" do
    test "não levanta exceção com temperature nil → exibe N/D" do
      output = Formatter.render(@location, %{@weather | temperature: nil})
      assert is_binary(output)
      assert output =~ "N/D"
    end

    test "não levanta exceção com feels_like nil → exibe N/D" do
      output = Formatter.render(@location, %{@weather | feels_like: nil})
      assert is_binary(output)
      assert output =~ "N/D"
    end

    test "não levanta exceção com ambos nil" do
      output = Formatter.render(@location, %{@weather | temperature: nil, feels_like: nil})
      assert is_binary(output)
    end
  end

  describe "render/2 — temperaturas extremas" do
    test "temperatura negativa (regiões frias)" do
      output = Formatter.render(@location, %{@weather | temperature: -5.0, feels_like: -9.2})
      assert output =~ "-5.0°C"
      assert output =~ "-9.2°C"
    end

    test "temperatura muito alta (regiões áridas)" do
      output = Formatter.render(@location, %{@weather | temperature: 48.3, feels_like: 52.0})
      assert output =~ "48.3°C"
      assert output =~ "52.0°C"
    end
  end
end
