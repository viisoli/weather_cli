defmodule WeatherCli.ForecastTest do
  use ExUnit.Case, async: true

  alias WeatherCli.Forecast

  describe "fetch/2 — validação de argumentos" do
    test "nil, nil → {:error, string}" do
      assert {:error, msg} = Forecast.fetch(nil, nil)
      assert is_binary(msg)
    end

    test "strings → {:error, string}" do
      assert {:error, msg} = Forecast.fetch("-23.5", "-46.6")
      assert is_binary(msg)
    end

    test "atoms → {:error, string}" do
      assert {:error, msg} = Forecast.fetch(:lat, :lon)
      assert is_binary(msg)
    end
  end

  describe "fetch/2 — integração com API" do
    @tag :integration
    test "retorna 5 dias para coordenadas válidas (São Paulo)" do
      assert {:ok, forecast} = Forecast.fetch(-23.5505, -46.6333)
      assert length(forecast.days) == 5
      assert is_binary(forecast.unit)
    end

    @tag :integration
    test "cada dia tem os campos obrigatórios" do
      assert {:ok, %{days: [day | _]}} = Forecast.fetch(-23.5505, -46.6333)
      assert %Date{} = day.date
      assert is_number(day.temp_max)
      assert is_number(day.temp_min)
      assert is_binary(day.condition)
      assert is_integer(day.rain_probability)
      assert day.rain_probability in 0..100
      assert is_number(day.wind_speed_max)
    end

    @tag :integration
    test "temp_max >= temp_min em todos os dias" do
      assert {:ok, %{days: days}} = Forecast.fetch(-23.5505, -46.6333)

      Enum.each(days, fn day ->
        assert day.temp_max >= day.temp_min,
               "temp_max #{day.temp_max} < temp_min #{day.temp_min} em #{day.date}"
      end)
    end

    @tag :integration
    test "primeiro dia é hoje ou amanhã (tolerância de fuso horário)" do
      assert {:ok, %{days: [first | _]}} = Forecast.fetch(-23.5505, -46.6333)
      today = Date.utc_today()
      assert first.date == today or first.date == Date.add(today, 1)
    end

    @tag :integration
    test "nunca levanta exceção para coordenadas numéricas" do
      result = Forecast.fetch(0.0, 0.0)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end
end
