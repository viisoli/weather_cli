defmodule WeatherCli.CacheTest do
  use ExUnit.Case, async: false

  alias WeatherCli.Cache

  # flush/0 now clears both memory AND the disk file, giving each test a clean slate.
  setup do
    Cache.flush()
    :ok
  end

  describe "get/1 e put/2" do
    test "retorna :miss para chave inexistente" do
      assert :miss = Cache.get("inexistente")
    end

    test "retorna {:ok, value} após put" do
      Cache.put("sp", :valor)
      assert {:ok, :valor} = Cache.get("sp")
    end

    test "armazena qualquer tipo de valor" do
      payload = {%{name: "São Paulo", country: "Brasil"}, %{temperature: 22.5}}
      Cache.put("sp", payload)
      assert {:ok, ^payload} = Cache.get("sp")
    end

    test "sobrescreve entrada existente" do
      Cache.put("sp", :antigo)
      Cache.put("sp", :novo)
      assert {:ok, :novo} = Cache.get("sp")
    end
  end

  describe "expiração por TTL" do
    test "entrada expirada retorna :miss" do
      Cache.put("sp", :valor, ttl: 1)
      Process.sleep(5)
      assert :miss = Cache.get("sp")
    end

    test "entrada dentro do TTL retorna {:ok, value}" do
      Cache.put("sp", :valor, ttl: 5_000)
      assert {:ok, :valor} = Cache.get("sp")
    end

    test "entradas com TTLs diferentes expiram independentemente" do
      Cache.put("curto", :expira_logo, ttl: 1)
      Cache.put("longo", :fica_aqui, ttl: 5_000)
      Process.sleep(5)
      assert :miss = Cache.get("curto")
      assert {:ok, :fica_aqui} = Cache.get("longo")
    end

    test "TTL padrão é 1 hora" do
      # Verifica indiretamente: uma entrada recém-inserida não expira em 100ms
      Cache.put("sp", :valor)
      Process.sleep(100)
      assert {:ok, :valor} = Cache.get("sp")
    end
  end

  describe "get_stale/1 — fallback offline" do
    test "retorna :miss para chave nunca armazenada" do
      assert :miss = Cache.get_stale("inexistente")
    end

    test "retorna {:ok, value, age} para entrada fresca" do
      Cache.put("sp", :valor)
      assert {:ok, :valor, age} = Cache.get_stale("sp")
      assert age >= 0 and age < 5
    end

    test "retorna {:ok, value, age} mesmo após expiração (fallback offline)" do
      Cache.put("sp", :valor, ttl: 1)
      Process.sleep(5)
      assert :miss = Cache.get("sp")
      assert {:ok, :valor, age} = Cache.get_stale("sp")
      assert age >= 0
    end

    test "retorna :miss para entrada explicitamente invalidada" do
      Cache.put("sp", :valor)
      Cache.invalidate("sp")
      assert :miss = Cache.get_stale("sp")
    end
  end

  describe "persistência em disco" do
    test "cache file é criado após put" do
      cache_file = Application.get_env(:weather_cli, :cache_file)
      Cache.put("sp", :valor)
      # cast é assíncrono — aguarda a escrita
      Process.sleep(20)
      assert File.exists?(cache_file)
    end

    test "cache file é removido após flush" do
      cache_file = Application.get_env(:weather_cli, :cache_file)
      Cache.put("sp", :valor)
      Process.sleep(20)
      Cache.flush()
      refute File.exists?(cache_file)
    end

    test "dados persistem entre 'sessões' (simulado por leitura direta do disco)" do
      cache_file = Application.get_env(:weather_cli, :cache_file)
      Cache.put("sp", :dado_persistido)
      Process.sleep(20)

      # Lê o arquivo e verifica que o dado está lá
      {:ok, binary} = File.read(cache_file)
      entries = :erlang.binary_to_term(binary, [:safe])
      assert Map.has_key?(entries, "sp")
    end

    test "arquivo corrompido não levanta exceção — inicia com cache vazio" do
      corrupted = Path.join(System.tmp_dir!(), "corrupted_cache_#{:erlang.unique_integer([:positive])}.bin")
      File.write!(corrupted, "nao sou um termo erlang valido")

      # Starts an anonymous (unnamed) Cache pointing to the corrupted file
      # so it doesn't conflict with the supervised WeatherCli.Cache process.
      {:ok, pid} = GenServer.start_link(Cache, cache_file: corrupted)

      assert :miss = GenServer.call(pid, {:get, "qualquer_chave"})

      GenServer.stop(pid)
      File.rm(corrupted)
    end
  end

  describe "invalidate/1" do
    test "remove a entrada da memória" do
      Cache.put("sp", :valor)
      Cache.invalidate("sp")
      assert :miss = Cache.get("sp")
    end

    test "não afeta outras entradas" do
      Cache.put("sp", :sp)
      Cache.put("rj", :rj)
      Cache.invalidate("sp")
      assert :miss = Cache.get("sp")
      assert {:ok, :rj} = Cache.get("rj")
    end

    test "não levanta erro para chave inexistente" do
      assert :ok = Cache.invalidate("nao_existe")
    end
  end

  describe "flush/0" do
    test "remove todas as entradas da memória" do
      Cache.put("sp", :sp)
      Cache.put("rj", :rj)
      Cache.flush()
      assert :miss = Cache.get("sp")
      assert :miss = Cache.get("rj")
    end

    test "remove entradas stale da memória" do
      Cache.put("sp", :sp, ttl: 1)
      Process.sleep(5)
      Cache.flush()
      assert :miss = Cache.get_stale("sp")
    end
  end

  describe "size/0" do
    test "retorna 0 com cache vazio" do
      assert 0 = Cache.size()
    end

    test "conta apenas entradas não expiradas" do
      Cache.put("sp", :sp, ttl: 5_000)
      Cache.put("rj", :rj, ttl: 5_000)
      Cache.put("expira", :x, ttl: 1)
      Process.sleep(5)
      assert 2 = Cache.size()
    end
  end

  describe "cache_key/1" do
    test "normaliza para minúsculas" do
      assert Cache.cache_key("São Paulo") == "são paulo"
      assert Cache.cache_key("LONDON") == "london"
    end

    test "remove espaços nas bordas" do
      assert Cache.cache_key("  Tokyo  ") == "tokyo"
    end

    test "chaves diferentes para cidades diferentes" do
      refute Cache.cache_key("São Paulo") == Cache.cache_key("Rio de Janeiro")
    end

    test "mesma chave para variações de maiúsculas" do
      assert Cache.cache_key("London") == Cache.cache_key("london")
    end
  end

  describe "format_age/1" do
    test "menos de 1 minuto → segundos" do
      assert Cache.format_age(0) == "0 segundos"
      assert Cache.format_age(59) == "59 segundos"
    end

    test "entre 1 e 2 minutos → '1 minuto'" do
      assert Cache.format_age(60) == "1 minuto"
      assert Cache.format_age(119) == "1 minuto"
    end

    test "2 a 59 minutos → plural de minutos" do
      assert Cache.format_age(120) == "2 minutos"
      assert Cache.format_age(3599) == "59 minutos"
    end

    test "entre 1 e 2 horas → '1 hora'" do
      assert Cache.format_age(3600) == "1 hora"
      assert Cache.format_age(7199) == "1 hora"
    end

    test "2+ horas → plural de horas" do
      assert Cache.format_age(7200) == "2 horas"
      assert Cache.format_age(10800) == "3 horas"
    end
  end
end
