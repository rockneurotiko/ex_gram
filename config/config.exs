import Config

config :ex_gram, token: "TOKEN", adapter: ExGram.Adapter.Tesla, json_engine: Jason, delete_webhook: true

config :logger, level: :debug

config :tesla, adapter: Tesla.Adapter.Gun, disable_deprecated_builder_warning: true

import_config "#{Mix.env()}.exs"
