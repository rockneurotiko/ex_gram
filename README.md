# ExGram

[![Hex.pm](https://img.shields.io/hexpm/v/ex_gram.svg)](http://hex.pm/packages/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_gram.svg)](https://hex.pm/packages/ex_gram)
[![Inline docs](http://inch-ci.org/github/rockneurotiko/ex_gram.svg)](http://inch-ci.org/github/rockneurotiko/ex_gram)
[![Build Status](https://travis-ci.org/rockneurotiko/ex_gram.svg?branch=master)](https://travis-ci.org/rockneurotiko/ex_gram)

ExGram is a library to build Telegram Bots, you can use the low-level methods and models, or use the really opinionated framework included.

## Installation

Add `ex_gram` as dependency in `mix.exs`

- Using Hex

``` elixir
def deps do
    [
      {:ex_gram, "~> 0.5.0"},
      # You need to specify one JSON engine, Jason or Poison
      # By default it will try to use Jason
      # See the Configuration section
      {:jason, ">= 1.0.0"}, # Only one of this
      {:poison, ">= 1.0.0"} # Two dependencies
    ]
end
```

## Configuration

There are some optional configuration that you can add to your `config.exs`:

### JSON Engine

By default ExGram will use `Jason` engine, but you can change it to your prefered JSON engine, the module just have to expose encode/2, encode!/2, decode/2, decode!/2

You can change the engine in the configuration:

``` elixir
config :ex_gram, json_encoder: Poison
```

### Token


``` elixir
config :ex_gram, token: "TOKEN"
```

This configuration will be used by default, but you can specify on every call a token or a bot to use.

If you use the framework, you will need to add `ExGram` and your bot (let's say it's `MyBot`) to your application:

``` elixir
children = [
  ExGram # This will setup the Registry.ExGram,
  {MyBot, [method: :polling, token: "TOKEN"]}
]
```

## Framework Usage

This section will show how to use the opinionated framework `ex_gram` for telegram bots!

### Creating a bot!

WIP

### Sending files

WIP

## Library Usage

Sometimes you just want to be able to send messages to some channel, or you don't like the way the framework works and want to be your own manager of the messages flows. For that cases, the low level API allows you to use the `ex_gram` library as raw as possible.

You can configure `ex_gram` in `config.exs` as explained in the Configuration section (you don't need to add anything to the application if you don't want to use the framework) and just use the low level API, for example:

``` elixir
ExGram.send_message("@my_channel", "Sending messages!!!")
```

Alternatively, you can not configure ex_gram at all (or use this to use different bots, having one configured or not), and use the extra parameter `token`:

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

If a method have mandatory arguments will be the arguments (in order that are defined on the documentation) to the method, all the optional values will go in the last argument as keyword list.

Also, the parameters must be of the types defined on the documentation (if multiple types, it must be one of them), and the method will return the model assigned of the one in the documentation. If you want to see the parameters and types that gets and returns a method, you can use the `h` method in an `Iex` instance:

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

For example, the method "getUpdates" from the documentation will be `get_updates`, and this one takes 4 optional parameters, we'll use on the example the parameters `offset` and `limit`:

``` elixir
ExGram.get_updates(offset: 123, limit: 100)
```

Another example, the method "sendMessage" it's `send_message`, this one have two mandatory parameters, `chat_id` (either an integer or a string) and `text` (a string), and 5 optional parameters:

``` elixir
ExGram.send_message("@rockneurotiko", "Hey bro! Checkout the ExGram library!", disable_notification: true)
```

### Extra options

All the methods have three extra options:

- `debug`: When true it will print the HTTP request response.
- `token`: It will use this token for the request
- `bot`: It will search on `Registry.ExGram` the `bot` name to extract the token. This registry is setted up by `ExGram` and all the bots made by the framework will register on it.

Note: Only one of `token` and `bot` must be used.

### How it's made?

There is a python script called `extractor.py`, that scrapes the Telegram Bot API documentation and prints to the stdout the lines needed to create all the methods and models, this auto generated lines uses two macros defined on `lib/ex_gram/macros.ex`: `method` and `model`.

#### Custom types defined

- `:string` -> `String.t()`
- `:int` or `:integer` -> `integer`
- `:bool` or `:boolean` -> `boolean`
- `:file` -> `{:file, String.t()}`
- `{:array, t}` -> `[t]`
- Any ExGram.Model


#### Model macro

Parameters:
1. Name of the model
2. Properties of the model, it's a list of tuples, where the first parameter is the name of the property, and the second one is the type.

This macro is the simple one, just create a module with the first name passed and use the params to create the struct and typespecs.

#### Method macro

Parameters:
1. Verb of the method (`:get` or `:post`)
2. Name of the method as string, it will be underscored.
3. The parameters of the method, this is a list of tuples, the tuples contains:
- Name of the parameters
- Type(s) of the parameter, it is a list of types, if there are more than one type on the list, it is expected one of them.
- An optional third parameter (always `:optional`) to set that parameter as optional
4. The type to be returned, it can be a model.

The macro will create two methods, one that will return tuple ok|error, and a banged(!) version that will raise if there are some error.

This methods do some stuff, like retrieving the token, check the parameters types, set up the body of some methods/verbs (specially the ones with files), call the method and parse the result.

## Creating your own updates worker

The ExGram framework use updates worker to "receive" the updates and send them to the dispatcher, this is the first parameter that you provide to your bot, the ones currently are `:polling` that goes to the module `ExGram.Updates.Polling` for polling updates and `:noup` that uses `ExGram.Updates.NoUp` that do nothing (great for some offline testing). Sadly the webhook and test worker are on the way.

But you can implement your own worker to retrieve the updates as you want!

The only specs are that `start_link` will receive `{:bot, <pid>, :token, <token>}`, the PID is where you should send the updates, and the token is that specific token so your worker will be able to use it to retrieve the updates.

Whenever you have and update `ExGram.Model.Update`, send it to the bot's PID like: `{:update, <update>}` with `Genserver.call`.

You can see the code of `ExGram.Updates.Polling`.
