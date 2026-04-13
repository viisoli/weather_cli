# WeatherCli 🌤

Aplicativo de linha de comando em Elixir que exibe a **temperatura atual** de qualquer cidade do mundo.

Usa a [Open-Meteo](https://open-meteo.com/) — gratuita, sem cadastro e sem API key.

```
🔍 Buscando clima para "São Paulo"...

╔══════════════════════════════════════╗
║         PREVISÃO DO TEMPO            ║
╚══════════════════════════════════════╝

  📍 São Paulo, Brasil
  ☁️  Parcialmente nublado

  🌡  Temperatura:    22.5°C
  🤔 Sensação:       20.1°C
  💧 Umidade:        78%
  💨 Vento:          14.0 km/h

════════════════════════════════════════
```

---

## Pré-requisitos

- **Erlang/OTP 25+** — [instalação](https://www.erlang.org/downloads)
- **Elixir 1.15+** — [instalação](https://elixir-lang.org/install.html)

> Dica: a forma mais simples de instalar ambos é via [asdf](https://asdf-vm.com/) ou [mise](https://mise.jdx.dev/).

---

## Instalação

```bash
git clone https://github.com/seu-usuario/weather_cli.git
cd weather_cli
mix deps.get
```

---

## Como usar

```bash
mix weather "São Paulo"     # consulta direta
mix weather                 # modo interativo (solicita a cidade)
```

O app aceita nomes de cidades em português ou inglês.

---

## Testes

```bash
mix test
```
