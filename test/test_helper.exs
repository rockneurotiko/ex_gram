ExUnit.start()

# Load support files
files = Path.wildcard("#{__DIR__}/support/**/*.exs")
Enum.each(files, &Code.require_file(&1, __DIR__))
