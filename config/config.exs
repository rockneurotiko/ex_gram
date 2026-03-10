import Config

config :ex_gram, token: "TOKEN", adapter: ExGram.Adapter.Req, json_engine: Jason, delete_webhook: true

config :logger, level: :debug

import_config "#{Mix.env()}.exs"
