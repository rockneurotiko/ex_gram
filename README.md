# ExGram

[![Hex.pm](https://img.shields.io/hexpm/v/ex_gram.svg)](http://hex.pm/packages/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Build Status](https://travis-ci.com/rockneurotiko/ex_gram.svg?branch=master)](https://travis-ci.com/rockneurotiko/ex_gram)

ExGram is a library to build Telegram Bots, you can use the low-level methods and models, or use the really opinionated framework included.

## Installation

Add `ex_gram` as dependency in `mix.exs`

``` elixir
def deps do
    [
      {:ex_gram, "~> 0.56"},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.12"},
      {:jason, ">= 1.0.0"}
    ]
end
```

See the next sections to select a different HTTP adapter or JSON engine.

### HTTP Adapter

You should add Tesla or custom HTTP adapter, by default it will try to use the Tesla adapter, these are the defaults:

On deps:
``` elixir
{:tesla, "~> 1.2"},
{:hackney, "~> 1.12"}
```

- If you want to use Gun:

On deps:
``` elixir
{:tesla, "~> 1.2"},
{:gun, "~> 1.3"}
```

On config:
``` elixir
config :tesla, adapter: Tesla.Adapter.Gun
```

- If you prefer your custom adapter instead of Tesla:

It must implement the behaviour `ExGram.Adapter`

On config:

``` elixir
config :ex_gram, adapter: YourCustomAdapter
```

### JSON Engine

By default ExGram will use `Jason` engine, but you can change it to your preferred JSON engine, the module just has to expose `encode/2`, `encode!/2`, `decode/2`, `decode!/2`.

You can change the engine in the configuration:

``` elixir
config :ex_gram, json_engine: Poison
```

## Configuration

There are some optional configurations that you can add to your `config.exs`:


### Token


``` elixir
config :ex_gram, token: "TOKEN"
```

This configuration will be used by default, but you can specify on every call a token or a bot to use.

If you use the framework, you will need to add `ExGram` and your bot (let's say it's `MyBot`) to your application:

``` elixir
children = [
  ExGram, # This will setup the Registry.ExGram
  {MyBot, [method: :polling, token: "TOKEN"]}
]
```

### Polling mode

The easiest way to get your bot runnig is using the Polling mode, it will use the method `getUpdates` on the telegram API to receive the new updates. You can read more about it here: https://core.telegram.org/bots/api#getting-updates

Setting this mode is as easy as defining the mode and the token in your supervisor:

``` elixir
children = [
  # ...
  {MyBot, [method: :polling, token: "TOKEN"]}
]
```

Additionally, you can configure the `getUpdates` call on the children options or on the application configuration.

- In children options

``` elixir
children = [
  # ...
  {MyBot, [method: {:polling, allowed_updates: ["message", "edited_message"]}, token: "TOKEN"]}
]
```

- In application configuration

``` elixir
config :ex_gram, :polling, allowed_updates: ["message", "edited_message"]
```

Webhooks might cause some issues if you are doing polling but if you have never used webhooks you can configure to not delete it.

```elixir
# This will not delete the webhook because it is never created.
# by default :delete_webhook is true
config :ex_gram, :polling, allowed_updates: ["message", "edited_message"], delete_webhook: false
```

This configuration takes priority over the ones on the configuration files, but you can combine them, for example having a default `allowed_updates` in the application configuration and in some bots where you need other updates overide it on the children options.


### Webhook mode

If you prefer to use webhook to have more performance receiving updates, you can use the provided Webhook mode.

The provided Webhook adapter uses `Plug`, you will need to have that dependency in your application, and add it to your router, with basic Plug Router it would look something like this:

``` elixir
defmodule AppRouter do
  use Plug.Router

  plug ExGram.Plug
end
```

At the moment the webhook URL will be `/telegram/<bot_token_hash>`.

Then, in your bots you have to specify the webhook updater when you start it on your supervisor tree:

``` elixir
children = [
  # ...
  {MyBot, [method: :webhook, token: "TOKEN"]}
]
```

In webhook mode, you can configure the following parameters:

``` elixir
config :ex_gram, :webhook,
  allowed_updates: ["message", "poll"],       # array of strings
  certificate: "priv/cert/selfsigned.pem",    # string (file path)
  drop_pending_updates: false,                # boolean
  ip_address: "1.1.1.1",                      # string
  max_connections: 50,                        # integer
  secret_token: "some_super_secret_key",      # string
  url: "http://bot.example.com:4000"          # string (domain name with scheme and maybe port)
```

You can also configure this options when starting inside the children options, you can configure it this way to ensure fine-grained setup per bot.

Example:

``` elixir
webhook_options = [allowed_updates: ["message", "poll"], certificate: "priv/...", ...] # All options described before
children = [
  # We use a tuple instead of the atom
  {MyBot, [method: {:webhook, webhook_options}, token: "TOKEN"]}
]
```

This configuration takes priority over the ones on the configuration files, but you can combine them, for example configuring the `certificate`, `ip_address` and `url` in the config file and the `allowed_updates` and `drop_pending_updates` in the children options.

For more information on each parameter, refer to this documentation: https://core.telegram.org/bots/api#setwebhook

### Test environment

Telegram has a Test Environment that you can use to test your bots, you can learn how to setup your bots there in this documentation: https://core.telegram.org/bots/webapps#using-bots-in-the-test-environment

In order to use the Test Environment you need to configure the bot like this:

``` elixir
config :ex_gram, test_environment: true
```

### Configure Tesla middlewares

If you are using the `Tesla` adapter, you can add [Tesla
middlewares](https://github.com/teamon/tesla#middleware) to `ExGram`
via config file. Add to your config:
```elixir
config :ex_gram, ExGram.Adapter.Tesla,
  middlewares: [
    {Tesla.Middleware.BaseUrl, "https://example.com/foo"}
  ]
```

The `middlewares` list will be loaded in the `ExGram.Adapter.Tesla` module.

In case you want to use a middleware that requires a function or any
invalid element for a configuration file, you can define a function in
any module that returns the Tesla configuration. Then put the `{m, f,
a}` in the configuration file, for example:
```elixir
# lib/tesla_middlewares.ex

defmodule TeslaMiddlewares do
  def retry() do
    {Tesla.Middleware.Retry,
     delay: 500,
     max_retries: 10,
     max_delay: 4_000,
     should_retry: fn
       {:ok, %{status: status}} when status in [400, 500] -> true
       {:ok, _} -> false
       {:error, _} -> true
     end}
  end
end
```

And in the config file:
```elixir
# config/config.exs

config :ex_gram, ExGram.Adapter.Tesla,
  middlewares: [
    {TeslaMiddlewares, :retry, []}
  ]
```

Take into account that the defined function has to return a two-tuple
as the Tesla config requires.

## Framework Usage

This section will show how to use the opinionated framework `ex_gram` for Telegram bots!

### Creating a bot!

Creating a bot is pretty simple, you can use the `mix bot.new` task to setup your bot. For example:

``` shell
$ mix new my_bot --sup
$ cd my_bot
```

Add and setup `ExGram` and it's adapters in your project as shown in the [Installation](#installation) section. After that, get the project deps and run the bot new task:

``` shell
$ mix deps.get
$ mix bot.new
```

You will get a message like this:

``` text
You should also add ExGram and MyBot.Bot as children of the application Supervisor,
here is an example using polling:

children = [
  ExGram,
  {MyBot.Bot, [method: :polling, token: token]}
]
```

This is basically telling you to configure the project as shown in the [Configuration](#configuration) section. Get your token and put `ExGram` and `MyBot.Bot` under the `Application`.

Now you are ready to run the bot with `mix run --no-halt`, go to Telegram and send your bot the command `/start`.

### How to handle messages

If you followed the [Creating a bot!](#creating-a-bot) section you should see a `handle/2` function in your `MyBot.Bot` module that looks like this:

``` elixir
def handle({:command, "start", _msg}, context) do
  answer(context, "Hi!")
end
```

The `handle/2` function receives two arguments:
  - The first argument is a tuple that changes depending on the update. In this case we are expecting a command called `start` in Telegram, this means a `/start` message. This type of commands can be sent next to a message, for example `/start Well hello`, in this cases the `Well hello` text will arrive to the third element of the tuple named `_msg` (because we are ignoring it right now). In case no text is given an empty string will arrive in the third element.

  - The second argument is a map called Context (`%ExGram.Cnt{}`) with information about the update that just arrived, with information like the [message object](https://core.telegram.org/bots/api#message) and internal data that `ExGram` will use to answer the message. You can also save your own information from your own middlewares in the `:extra` key using the `add_extra` method.

This are the type of tuples that `handle/2` can receive as first parameter:
  - `{:command, key, message}` → This tuple will match when a command is received
  - `{:text, text, message}` → This tuple will match when plain text is sent to the bot (check [privacy mode](https://core.telegram.org/bots#privacy-mode))
  - `{:regex, key, message}` → This tuple will match if a regex is defined at the beginning of the module
  - `{:location, location}` → This tuple will match when a location message is received
  - `{:callback_query, callback_query}` → This tuple will match when a [Callback Query](https://core.telegram.org/bots/api#callbackquery) is received
  - `{:inline_query, inline_query}` → This tuple will match when an [Inline Query](https://core.telegram.org/bots/api#inlinequery) is received
  - `{:edited_message, edited_message}` → This tuple will match when a message is edited
  - `{:message, message}` → This will match any message that does not fit with the ones described above
  - `{:update, update}` → This tuple will match as a default handle

### Execute code on initialization

The bots have an optional callback that will be executed *before* starting to consume messages. This method can be used to initialize things before starting the bot, for example setting the bot's description or name.

The callback is `init/1`, the parameter is a keyword list with two values, `:bot` which is the bot's name, and `:token` with the token used when starting the bot. Either of this can be used when calling `ExGram` methods.

Example of usage:

``` elixir
defmodule MyBot.Bot do
  @bot :my_bot

  use ExGram.Bot, name: @bot

  def init(opts) do
    ExGram.set_my_description!(description: "This is my description", bot: opts[:bot]) # with :bot
    ExGram.set_my_name!(name: "My Bot", token: opts[:token]) # with :token
    :ok
  end

  # ...
end
```

### Sending files

`ExGram` lets you send files by id (this means using files already uploaded to Telegram servers), providing a local path, or with the content directly. Some examples of this methods for sending files:
``` elixir
ExGram.send_document(chat_id, document_id)                                     # By document ID

ExGram.send_document(chat_id, {:file, "path/to/file"})                         # By local path

ExGram.send_document(chat_id, {:file_content, "FILE CONTENT", "filename.txt"}) # By content
```

This three ways of sending files works when the API has a file field, for example `send_photo`, `send_audio`, `send_video`, ...

## Library Usage

Sometimes you just want to be able to send messages to some channel, or you don't like the way the framework works and want to be your own manager of the messages flows. For that cases, the low level API allows you to use the `ex_gram` library as raw as possible.

You can configure `ex_gram` in `config.exs` as explained in the Configuration section (you don't need to add anything to the application if you don't want to use the framework) and just use the low level API, for example:

``` elixir
ExGram.send_message("@my_channel", "Sending messages!!!")
```

Alternatively, you can not configure `ex_gram` at all (or use this to use different bots, having one configured or not), and use the extra parameter `token`:

``` elixir
ExGram.send_message("@my_channel", "Sending messages!!!", token: "BOT_TOKEN")
```

If you want to know how the low level API is designed and works, you can read the next section.


## Low level API

All the models and methods are equal one to one with the models and methods defined on the [Telegram Bot API Documentation](https://core.telegram.org/bots/api)!

### Models

All the models are inside of the `ExGram.Model` module. You can see all the models in `lib/ex_gram.ex` file, for example `User`:

``` elixir
model(User, [
  {:id, :integer},
  {:is_bot, :boolean},
  {:first_name, :string},
  {:last_name, :string},
  {:username, :string},
  {:language_code, :string}
])
```

Also, all the models have the type `t` defined, so you can use it on your typespecs or see their types inside of an IEx console:

``` elixir
>>> t ExGram.Model.User
@type t() :: %ExGram.Model.User{
  first_name: String.t(),
  id: integer(),
  is_bot: boolean(),
  language_code: String.t(),
  last_name: String.t(),
  username: String.t()
}
```

### Methods

All the methods are inside of the `ExGram` module, they are like the documentation ones but in snake_case instead of camelCase.

If a method has mandatory arguments they will be the arguments (in order that are defined on the documentation) to the method, all the optional values will go in the last argument as keyword list.

Also, the parameters must be of the types defined on the documentation (if multiple types, it must be one of them), and the method will return the model assigned of the one in the documentation. If you want to see the parameters and types that a method gets and returns, you can use the `h` method in an `IEx` instance:

``` elixir
>>> h ExGram.send_message

def send_message(chat_id, text, ops \\ [])

@spec send_message(
  chat_id :: integer() | String.t(),
  text :: String.t(),
  ops :: [
    parse_mode: String.t(),
    disable_web_page_preview: boolean(),
    disable_notification: boolean(),
    reply_to_message_id: integer(),
    reply_markup:
      ExGram.Model.InlineKeyboardMarkup.t()
      | ExGram.Model.ReplyKeyboardMarkup.t()
      | ExGram.Model.ReplyKeyboardRemove.t()
      | ExGram.Model.ForceReply.t()
    ]
) :: {:ok, ExGram.Model.Message.t()} | {:error, ExGram.Error.t()}
```

All the methods have their unsafe brother with the name banged(!) (`get_me!` for the `get_me` method) that instead of returning `{:ok, model} | {:error, ExGram.Error}` will return `model` and raise if there is some error.

For example, the method "getUpdates" from the documentation will be `get_updates`, and this one takes 4 optional parameters. We'll use the parameters `offset` and `limit`:

``` elixir
ExGram.get_updates(offset: 123, limit: 100)
```

Another example, the method "sendMessage" is `send_message`, this one has two mandatory parameters, `chat_id` (either an integer or a string), `text` (a string), and 5 optional parameters:

``` elixir
ExGram.send_message("@rockneurotiko", "Hey bro! Checkout the ExGram library!", disable_notification: true)
```

### Extra options

All the methods have three extra options:

- `debug`: When `true` it will print the HTTP request response.
- `token`: It will use this token for the request.
- `bot`: It will search on `Registry.ExGram` the `bot` name to extract the token. This registry is set up by `ExGram`, and all the bots made by the framework will register on it.

Note: Only one of `token` and `bot` must be used.

### How it's made?

There is a Python script called `extractor.py`, it uses the [`telegram_api_json`](https://github.com/rockneurotiko/telegram_api_json) project that scrapes the Telegram Bot API documentation and provides a JSON with all the information, check the project description if you want to create your own projects that uses a standardized file to auto-generate the API.

This script uses the JSON description and prints to the stdout the lines needed to create all the methods and models, these auto-generated lines use two macros defined on `lib/ex_gram/macros.ex`: `method` and `model`.

#### Custom types defined

- `:string` -> `String.t()`
- `:int` or `:integer` -> `integer`
- `:bool` or `:boolean` -> `boolean`
- `:file` -> `{:file, String.t()}`
- `{:array, t}` -> `[t]`
- Any `ExGram.Model`


#### Model macro

Parameters:
1. Name of the model
2. Properties of the model, it's a list of tuples, where the first parameter is the name of the property and the second one is the type.

This macro is the simple one, just create a module with the first name passed and use the params to create the struct and typespecs.

#### Method macro

Parameters:
1. Verb of the method (`:get` or `:post`)
2. Name of the method as string, it will be underscored.
3. The parameters of the method, this is a list of tuples, the tuples contains:
- Name of the parameters
- Type(s) of the parameter, it is a list of types, if there are more than one type on the list, it is expected to have one of them.
- An optional third parameter (always `:optional`) to set that parameter as optional
4. The type to be returned, it can be a model.

The macro will create two methods, one that will return the tuple `ok|error`, and a banged(!) version that will raise if there is some error.

These methods do some stuff, like retrieving the token, checking the parameters types, setting up the body of some methods/verbs (specially the ones with files), calling the method and parsing the result.

## Creating your own updates worker

The ExGram framework uses updates worker to "receive" the updates and send them to the dispatcher, this is the first parameter that you provide to your bot, the ones currently are `:polling` that goes to the module `ExGram.Updates.Polling` for polling updates, `:webhook` that goes to the module `ExGram.Updates.Webhook` for webhook updates and `:noup` that uses `ExGram.Updates.NoUp` that do nothing (great for some offline testing). Sadly, the test worker are on the way.

But you can implement your own worker to retrieve the updates as you want!

The only specs are that `start_link` will receive `{:bot, <pid>, :token, <token>}`, the PID is where you should send the updates, and the token that your worker will be able to use to retrieve the updates.

Whenever you have an update `ExGram.Model.Update`, send it to the bot's PID like: `{:update, <update>}` with `GenServer.call`.

You can see the code of `ExGram.Updates.Polling`.
