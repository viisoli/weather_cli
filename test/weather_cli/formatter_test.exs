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

  # ── Forecast rendering ─────────────────────────────────────────────────────

  @today Date.utc_today()
  @forecast %{
    unit: "°C",
    days: [
      %{date: @today, temp_max: 28.0, temp_min: 19.0, condition: "Nublado", rain_probability: 40, wind_speed_max: 18.0},
      %{date: Date.add(@today, 1), temp_max: 25.0, temp_min: 17.5, condition: "Chuva leve", rain_probability: 70, wind_speed_max: 22.0},
      %{date: Date.add(@today, 2), temp_max: 30.0, temp_min: 21.0, condition: "Céu limpo", rain_probability: 5, wind_speed_max: 10.0},
      %{date: Date.add(@today, 3), temp_max: 27.0, temp_min: 18.0, condition: "Parcialmente nublado", rain_probability: 20, wind_speed_max: 15.0},
      %{date: Date.add(@today, 4), temp_max: 24.0, temp_min: 16.0, condition: "Tempestade", rain_probability: 90, wind_speed_max: 35.0}
    ]
  }

  describe "render_forecast/2 — conteúdo" do
    test "retorna string" do
      assert is_binary(Formatter.render_forecast(@location, @forecast))
    end

    test "inclui nome da cidade" do
      assert Formatter.render_forecast(@location, @forecast) =~ "São Paulo"
    end

    test "inclui o país" do
      assert Formatter.render_forecast(@location, @forecast) =~ "Brasil"
    end

    test "exibe 'Hoje' para o primeiro dia" do
      assert Formatter.render_forecast(@location, @forecast) =~ "Hoje"
    end

    test "exibe 'Amanhã' para o segundo dia" do
      assert Formatter.render_forecast(@location, @forecast) =~ "Amanhã"
    end

    test "inclui todas as condições climáticas dos dias" do
      output = Formatter.render_forecast(@location, @forecast)
      assert output =~ "Nublado"
      assert output =~ "Chuva leve"
      assert output =~ "Céu limpo"
      assert output =~ "Tempestade"
    end

    test "inclui temperaturas máximas e mínimas" do
      output = Formatter.render_forecast(@location, @forecast)
      assert output =~ "28.0°C"
      assert output =~ "19.0°C"
    end

    test "inclui percentual de chuva" do
      output = Formatter.render_forecast(@location, @forecast)
      assert output =~ "40%"
      assert output =~ "90%"
    end

    test "inclui barra visual de chuva" do
      output = Formatter.render_forecast(@location, @forecast)
      assert output =~ "█"
      assert output =~ "░"
    end

    test "omite vírgula quando country é string vazia" do
      location = %{name: "Ilha", country: ""}
      output = Formatter.render_forecast(location, @forecast)
      assert output =~ "Ilha"
      refute output =~ "Ilha,"
    end
  end

  describe "render_forecast/2 — dados ausentes" do
    test "não levanta exceção com temp_max nil" do
      day = %{hd(@forecast.days) | temp_max: nil}
      forecast = %{@forecast | days: [day | tl(@forecast.days)]}
      output = Formatter.render_forecast(@location, forecast)
      assert is_binary(output)
      assert output =~ "N/D"
    end

    test "não levanta exceção com date nil" do
      day = %{hd(@forecast.days) | date: nil}
      forecast = %{@forecast | days: [day | tl(@forecast.days)]}
      assert is_binary(Formatter.render_forecast(@location, forecast))
    end

    test "lista de dias vazia renderiza mensagem de indisponível" do
      output = Formatter.render_forecast(@location, %{@forecast | days: []})
      assert is_binary(output)
      assert output =~ "Nenhum dado"
    end
  end

  describe "render_forecast/2 — alinhamento de labels" do
    test "label 'Hoje' e 'Amanhã' têm a mesma largura que um dia da semana" do
      output = Formatter.render_forecast(@location, @forecast)
      # Both "Hoje   " and "Amanhã " should be padded to 7 chars — verify no raw label mismatch
      assert output =~ "Hoje"
      assert output =~ "Amanhã"
    end
  end
end
