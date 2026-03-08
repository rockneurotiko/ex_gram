# Start the NimbleOwnership server for ExGram.Adapter.Test
{:ok, _} = ExGram.Adapter.Test.start_link()

ExUnit.start()
