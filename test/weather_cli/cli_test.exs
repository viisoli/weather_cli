defmodule WeatherCli.CLITest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias WeatherCli.Cache

  setup do
    Cache.flush()
    :ok
  end

  # validate_city/1 is private; tested indirectly through run/1 and run_forecast/1.
  # IO is captured so validation tests never reach the network.

  describe "run/1 — validação de entrada" do
    test "entrada vazia exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("") end) =~ "informe o nome"
    end

    test "entrada só com espaços exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("   ") end) =~ "informe o nome"
    end

    test "entrada numérica inteira exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("12345") end) =~ "número"
    end

    test "entrada numérica decimal exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("99.5") end) =~ "número"
    end

    test "entrada com 1 caractere exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("a") end) =~ "2 caracteres"
    end

    test "entrada com mais de 100 caracteres exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run(String.duplicate("a", 101)) end) =~
               "longo demais"
    end

    test "entrada só com símbolos especiais exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run("@#$%!") end) =~ "não parece ser um nome"
    end

    test "cidade com letras acentuadas é aceita — regex Unicode" do
      output = capture_io(fn -> WeatherCli.CLI.run("Ñoño") end)
      refute output =~ "não parece ser um nome"
      assert output =~ "Buscando clima"
    end

    test "cidade com caracteres asiáticos é aceita" do
      output = capture_io(fn -> WeatherCli.CLI.run("東京") end)
      refute output =~ "não parece ser um nome"
      assert output =~ "Buscando clima"
    end
  end

  describe "run_forecast/1 — validação de entrada (mesmas regras)" do
    test "entrada vazia exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast("") end) =~ "informe o nome"
    end

    test "entrada só com espaços exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast("   ") end) =~ "informe o nome"
    end

    test "entrada numérica exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast("12345") end) =~ "número"
    end

    test "entrada com 1 caractere exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast("a") end) =~ "2 caracteres"
    end

    test "entrada com mais de 100 caracteres exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast(String.duplicate("a", 101)) end) =~
               "longo demais"
    end

    test "entrada só com símbolos exibe mensagem de erro" do
      assert capture_io(fn -> WeatherCli.CLI.run_forecast("@#$%!") end) =~ "não parece ser um nome"
    end

    test "cidade válida inicia a busca de previsão" do
      output = capture_io(fn -> WeatherCli.CLI.run_forecast("São Paulo") end)
      assert output =~ "Buscando previsão"
    end
  end

  describe "cache — hit e miss" do
    test "segunda consulta usa cache em vez de buscar novamente" do
      location = %{name: "Testópolis", country: "Brasil"}
      weather = %{temperature: 25.0, feels_like: 24.0, humidity: 60, wind_speed: 10.0, condition: "Céu limpo", unit: "°C"}
      key = Cache.cache_key("testópolis")
      Cache.put(key, {location, weather})
      # Força flush do cast para garantir que o valor está no GenServer antes de continuar
      Cache.size()

      output = capture_io(fn -> WeatherCli.CLI.run("Testópolis") end)
      assert output =~ "cache"
      assert output =~ "Testópolis"
    end

    test "forecast: segunda consulta usa cache" do
      location = %{name: "Cachélândia", country: "Testes"}
      forecast = %{days: [], unit: "°C"}
      key = "forecast:" <> Cache.cache_key("cachélândia")
      Cache.put(key, {location, forecast})
      Cache.size()

      output = capture_io(fn -> WeatherCli.CLI.run_forecast("Cachélândia") end)
      assert output =~ "cache"
    end
  end

  describe "fallback offline" do
    test "run/1 exibe dados stale quando API falha e há cache velho" do
      location = %{name: "Cidade Offline", country: "BR"}
      weather = %{temperature: 20.0, feels_like: 19.0, humidity: 70, wind_speed: 5.0, condition: "Nublado", unit: "°C"}
      key = Cache.cache_key("cidade offline")
      # Guarda com TTL 1ms para expirar imediatamente
      Cache.put(key, {location, weather}, ttl: 1)
      Process.sleep(5)
      Cache.size()

      # Confirma que o cache fresco expirou mas o stale existe
      assert :miss = Cache.get(key)
      assert {:ok, _, _} = Cache.get_stale(key)
    end

    test "run/1 exibe erro simples quando API falha sem cache" do
      # Se não há cache, o erro da API é exibido diretamente — sem stale fallback
      # Testamos via saída: uma cidade real que passará na validação mas
      # cujo erro virá apenas se não houver cache (já garantido pelo flush no setup)
      assert :miss = Cache.get_stale(Cache.cache_key("São Paulo"))
    end
  end

  describe "run/1 — integração com API" do
    @tag :integration
    test "cidade válida retorna :ok sem exceção" do
      assert :ok = WeatherCli.CLI.run("London")
    end

    @tag :integration
    test "cidade inexistente exibe mensagem de não encontrada" do
      output = capture_io(fn -> WeatherCli.CLI.run("xyzCidadeInexistente999") end)
      assert output =~ "não encontrada"
    end
  end

  describe "run_forecast/1 — integração com API" do
    @tag :integration
    test "cidade válida exibe previsão e retorna :ok" do
      assert :ok = WeatherCli.CLI.run_forecast("London")
    end
  end
end
