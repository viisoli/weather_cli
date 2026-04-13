import Config

# Use a unique temp file per test run so tests never touch the real cache.
# The file is cleaned up by the test setup (Cache.flush/0 deletes it on disk too).
config :weather_cli, :cache_file,
  Path.join(System.tmp_dir!(), "weather_cli_test_cache.bin")
