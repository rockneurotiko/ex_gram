# Changelog

## Unreleased

## [0.11.0]
- Update Telegram API to 4.7

## [0.10.0]
- Update Telegram API to 4.6

## [0.9.0]
- Warn when fetching token by bot's name and there are no token
- Update Telegram API to 4.5

## [0.8.1]
- Add the ability to configure custom tesla middlewares
- Fix regex macros, couldn't compile

## [0.8.0]
- Add Tesla adapter for HTTP and setting it as default
- Add ability to select Tesla adapter (tested with hackney and gun)
- Added documentation
- Added template for creating a bot

## [0.7.1]
- Fix an error when not receiving updates the local update_id keeps increasing and makes an infinite loop of retrieving updates

## [0.7.0]
- Update to BOT API 4.4
- Set a softer version in README

## [0.6.2]
- Update to BOT API 4.3

## [0.6.1]
- Update to BOT API 4.2
- Add default handle_info handler and change timeout
- Remove Supervisor.Spec uses, clean start_link and child_spec code

## [0.6.0]

- Handle when update_worker is nil and raise a better message
- Add `{:edited_message, msg}` message
- Relax hackney version
- Allow to specify JSON engine to use `config :ex_gram, json_encoder: Jason`
- Http implementation details moved from `ExGram` to `ExGram.Adapter.Http`
