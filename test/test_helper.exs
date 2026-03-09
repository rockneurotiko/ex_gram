# Start the ExGram supervisor (which starts the Registry)
{:ok, _} = ExGram.start_link()

# Start the NimbleOwnership server for ExGram.Adapter.Test
{:ok, _} = ExGram.Adapter.Test.start_link()

ExUnit.start()
