# WeatherCli 🌤

Aplicativo de linha de comando em Elixir que exibe o **clima atual** ou a **previsão dos próximos 5 dias** de qualquer cidade do mundo.

Usa a [Open-Meteo](https://open-meteo.com/) — gratuita, sem cadastro e sem API key.

---

## Exemplos de saída

**Clima atual**
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

**Previsão de 5 dias**
```
🔍 Buscando previsão para "São Paulo"...

╔══════════════════════════════════════╗
║      PREVISÃO — PRÓXIMOS 5 DIAS      ║
╚══════════════════════════════════════╝

  📍 São Paulo, Brasil

  ────────────────────────────────────────
  📅 Hoje     13 Abr
     ☁️  Nublado
     🌡  Máx 28.0°C  ·  Mín 19.0°C
     🌧  Chuva 40% ██░░░  ·  💨 18.0 km/h

  ────────────────────────────────────────
  📅 Amanhã   14 Abr
     ☁️  Chuva leve
     🌡  Máx 25.0°C  ·  Mín 17.5°C
     🌧  Chuva 70% ███░░  ·  💨 22.0 km/h

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
git clone https://github.com/viisoli/weather_cli.git
cd weather_cli
mix deps.get
```

---

## Como usar

```bash
# Clima atual
mix weather "São Paulo"
mix weather                   # modo interativo

# Previsão dos próximos 5 dias
mix forecast "São Paulo"
mix forecast                  # modo interativo
```

O app aceita nomes de cidades em português ou inglês.

Os resultados ficam em **cache por 1 hora**. Se a conexão cair, os últimos dados disponíveis são exibidos com um aviso de quando foram obtidos.

---

## Testes

```bash
mix test
```
