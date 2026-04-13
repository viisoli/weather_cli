defmodule WeatherCli.Cache do
  @moduledoc """
  Persistent, TTL-based cache backed by a GenServer.

  ## Storage

  Entries are kept in memory and written to disk after every update so that
  cached results survive across CLI invocations. The file location is read from
  the application environment:

      config :weather_cli, :cache_file, "/path/to/cache.bin"

  Default (cross-platform):

  | Platform      | Default path                              |
  |---------------|-------------------------------------------|
  | macOS / Linux | `~/.weather_cli/cache.bin`                |
  | Windows       | `%USERPROFILE%\\.weather_cli\\cache.bin`  |

  The directory is created automatically if it does not exist.

  ## TTL

  The default TTL is **1 hour**. Custom TTL per entry:

      Cache.put(key, value, ttl: :timer.hours(6))

  ## Fresh vs. Stale

  - `get/1` — returns `{:ok, value}` only for non-expired entries.
  - `get_stale/1` — returns `{:ok, value, age_seconds}` for **any** stored entry,
    including expired ones. Use as an offline fallback when the API is unreachable.

  ## Usage

      Cache.put("são paulo", {location, weather})

      case Cache.get("são paulo") do
        {:ok, value}           -> display(value)
        :miss                  -> fetch_from_api()
      end

      case Cache.get_stale("são paulo") do
        {:ok, value, age}      -> display_with_warning(value, age)
        :miss                  -> show_error_no_data()
      end
  """

  use GenServer

  @default_ttl :timer.hours(1)

  # Entries older than this are pruned from disk on load to keep the file small.
  @max_stale_age :timer.hours(48)

  # ── Public API ─────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    gen_opts =
      case Keyword.get(opts, :name, __MODULE__) do
        nil -> []
        name -> [name: name]
      end

    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Returns `{:ok, value}` if the entry is present and **not** expired, `:miss` otherwise.
  """
  @spec get(term) :: {:ok, term} | :miss
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  @doc """
  Returns `{:ok, value, age_seconds}` for **any** stored entry — fresh or expired —
  where `age_seconds` is the time since the value was originally fetched.
  Returns `:miss` only if the key was never stored or explicitly invalidated.

  Intended as an offline fallback: serves the last known data when the API
  is unreachable and informs the user how old it is.
  """
  @spec get_stale(term) :: {:ok, term, non_neg_integer} | :miss
  def get_stale(key), do: GenServer.call(__MODULE__, {:get_stale, key})

  @doc """
  Stores `value` under `key` and persists to disk.

  Options:
  - `:ttl` — time-to-live in milliseconds (default: 1 hour)
  """
  @spec put(term, term, keyword) :: :ok
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    GenServer.cast(__MODULE__, {:put, key, value, ttl})
  end

  @doc "Removes a single entry from the cache and persists to disk."
  @spec invalidate(term) :: :ok
  def invalidate(key), do: GenServer.cast(__MODULE__, {:invalidate, key})

  @doc "Clears all entries from memory and removes the cache file from disk."
  @spec flush() :: :ok
  def flush, do: GenServer.call(__MODULE__, :flush)

  @doc "Returns the number of non-expired entries currently in the cache."
  @spec size() :: non_neg_integer
  def size, do: GenServer.call(__MODULE__, :size)

  # ── GenServer callbacks ─────────────────────────────────────────────────────

  @impl true
  def init(opts) do
    file = Keyword.get(opts, :cache_file, cache_file())
    entries = load_from_disk(file)
    {:ok, %{entries: entries, cache_file: file}}
  end

  @impl true
  def handle_call({:get, key}, _from, %{entries: entries} = state) do
    now = now_ms()

    reply =
      case Map.get(entries, key) do
        {value, _fetched_at, expires_at} when now < expires_at -> {:ok, value}
        _ -> :miss
      end

    {:reply, reply, state}
  end

  def handle_call({:get_stale, key}, _from, %{entries: entries} = state) do
    now = now_ms()

    reply =
      case Map.get(entries, key) do
        {value, fetched_at, _expires_at} ->
          {:ok, value, div(now - fetched_at, 1000)}

        nil ->
          :miss
      end

    {:reply, reply, state}
  end

  def handle_call(:size, _from, %{entries: entries} = state) do
    now = now_ms()
    count = Enum.count(entries, fn {_, {_, _, expires_at}} -> now < expires_at end)
    {:reply, count, state}
  end

  # flush/0 is a call so the caller blocks until the disk write is done.
  def handle_call(:flush, _from, %{cache_file: file} = state) do
    delete_cache_file(file)
    {:reply, :ok, %{state | entries: %{}}}
  end

  @impl true
  def handle_cast({:put, key, value, ttl}, %{entries: entries, cache_file: file} = state) do
    now = now_ms()
    updated = Map.put(entries, key, {value, now, now + ttl})
    persist(updated, file)
    {:noreply, %{state | entries: updated}}
  end

  def handle_cast({:invalidate, key}, %{entries: entries, cache_file: file} = state) do
    updated = Map.delete(entries, key)
    persist(updated, file)
    {:noreply, %{state | entries: updated}}
  end

  # ── Disk persistence ────────────────────────────────────────────────────────

  # Loads entries from disk, pruning very old stale entries to keep the file lean.
  # Returns an empty map on any read or decode error (graceful degradation).
  defp load_from_disk(nil), do: %{}

  defp load_from_disk(file) do
    with true <- File.exists?(file),
         {:ok, binary} <- File.read(file),
         {:ok, entries} <- safe_decode(binary) do
      prune_old_entries(entries)
    else
      _ -> %{}
    end
  end

  # Writes entries to disk. Creates the directory if needed.
  # Errors are silently swallowed — a failed write is not fatal.
  defp persist(_entries, nil), do: :ok

  defp persist(entries, file) do
    dir = Path.dirname(file)

    with :ok <- File.mkdir_p(dir),
         :ok <- File.write(file, :erlang.term_to_binary(entries)) do
      :ok
    else
      {:error, _} -> :ok
    end
  end

  defp delete_cache_file(nil), do: :ok
  defp delete_cache_file(file), do: File.rm(file)

  # :erlang.binary_to_term with [:safe] rejects binaries that reference atoms
  # not already in the atom table, reducing the risk from a corrupted file.
  defp safe_decode(binary) do
    try do
      {:ok, :erlang.binary_to_term(binary, [:safe])}
    rescue
      _ -> :error
    end
  end

  # Remove entries that expired more than @max_stale_age ago to keep the file small.
  defp prune_old_entries(entries) do
    cutoff = now_ms() - @max_stale_age
    Map.filter(entries, fn {_, {_, fetched_at, _}} -> fetched_at > cutoff end)
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  # Uses wall-clock (system) time so timestamps remain valid across process restarts.
  defp now_ms, do: System.system_time(:millisecond)

  # Reads the cache file path from application config.
  # Falls back to ~/.weather_cli/cache.bin if not configured.
  defp cache_file do
    Application.get_env(
      :weather_cli,
      :cache_file,
      Path.join([System.user_home() || System.tmp_dir!(), ".weather_cli", "cache.bin"])
    )
  end

  @doc """
  Normalizes a city name into a cache key.
  Strips surrounding whitespace and lowercases so "São Paulo" and "são paulo"
  share the same cache entry.
  """
  @spec cache_key(String.t()) :: String.t()
  def cache_key(city), do: city |> String.trim() |> String.downcase()

  @doc """
  Formats an age in seconds into a human-readable Portuguese string.

      iex> WeatherCli.Cache.format_age(30)
      "30 segundos"
      iex> WeatherCli.Cache.format_age(90)
      "1 minuto"
      iex> WeatherCli.Cache.format_age(3700)
      "1 hora"
  """
  @spec format_age(non_neg_integer) :: String.t()
  def format_age(seconds) when seconds < 60, do: "#{seconds} segundos"
  def format_age(seconds) when seconds < 120, do: "1 minuto"
  def format_age(seconds) when seconds < 3600, do: "#{div(seconds, 60)} minutos"
  def format_age(seconds) when seconds < 7200, do: "1 hora"
  def format_age(seconds), do: "#{div(seconds, 3600)} horas"
end
