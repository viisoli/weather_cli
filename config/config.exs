import Config

# Default cache file location — works on macOS, Linux and Windows.
# The directory is created automatically if it does not exist.
config :weather_cli, :cache_file,
  Path.join([System.user_home() || System.tmp_dir!(), ".weather_cli", "cache.bin"])

import_config "#{config_env()}.exs"
