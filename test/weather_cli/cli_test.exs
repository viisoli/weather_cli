defmodule WeatherCli.CLITest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  # validate_city/1 is private; tested indirectly through run/1.
  # IO is captured so no real HTTP calls happen for the validation tests.

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

    test "cidade com letras acentuadas é aceita (bug de regex Unicode)" do
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

  describe "run/1 — integração com API" do
    @tag :integration
    test "entrada válida inicia a busca e retorna :ok" do
      assert :ok = WeatherCli.CLI.run("London")
    end

    @tag :integration
    test "cidade inexistente exibe mensagem de não encontrada" do
      output = capture_io(fn -> WeatherCli.CLI.run("xyzCidadeInexistente999") end)
      assert output =~ "não encontrada"
    end
  end
end
