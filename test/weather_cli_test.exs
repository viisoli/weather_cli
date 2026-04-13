defmodule WeatherCliTest do
  use ExUnit.Case, async: true

  describe "WeatherCli public API" do
    test "run/1 delega para CLI.run/1" do
      # Verifica que o módulo raiz expõe as funções documentadas
      fns = WeatherCli.__info__(:functions)
      assert {:run, 0} in fns
      assert {:run, 1} in fns
      assert {:run_forecast, 0} in fns
      assert {:run_forecast, 1} in fns
    end
  end
end
