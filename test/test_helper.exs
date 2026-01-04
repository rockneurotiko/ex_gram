ExUnit.start()

# Start ExGram supervisor to ensure Registry.ExGram is available for all tests
{:ok, _} = ExGram.start_link()
