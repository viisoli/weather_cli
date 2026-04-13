defmodule WeatherCliTest do
  use ExUnit.Case, async: true

  describe "WeatherCli" do
    test "módulo exporta run/0 e run/1 via argumento padrão" do
      fns = WeatherCli.__info__(:functions)
      arities = fns |> Enum.filter(fn {name, _} -> name == :run end) |> Enum.map(&elem(&1, 1))
      assert 0 in arities
      assert 1 in arities
    end
  end
end
