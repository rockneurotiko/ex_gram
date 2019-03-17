# Changelog

## [0.6.0]

- Handle when update_worker is nil and raise a better message
- Add `{:edited_message, msg}` message
- Relax hackney version
- Allow to specify JSON engine to use `config :ex_gram, json_encoder: Jason`
- Http implementation details moved from `ExGram` to `ExGram.Adapter.Http`
