# How to deploy a bot to Fly.io

Most of this guide is generic and can be applied to other providers, but since fly.io has a free tier that we can use to run bots it's a great way to start into deploying bots.

## Setup Fly App

If you already have the app running in Fly, you can skip this section.

The free tier on fly.io allows you to have 3 machines with size `shared-cpu-1x@256MB`, for this example setup we'll create one for the elixir application and one for postgresql.

First we need to install the `fly` command utility, follow the instructions for your platform: https://fly.io/docs/hands-on/install-flyctl/

We want to use our own Dockerfile, because we have more control in how we deploy our application, here is the Dockerfile that I use:

In this example the application is called `my_bot`, change the path in the `CMD` command with your app's name

- `Dockerfile`
``` dockerfile
FROM hexpm/elixir:1.16.2-erlang-26.2.3-alpine-3.19.1 as base

RUN mkdir /app
WORKDIR /app

RUN apk --no-cache add g++ make git && mix local.hex --force && mix local.rebar --force

FROM base as test
COPY . /app

FROM base AS app_builder
ENV MIX_ENV=prod

# copy only deps-related files
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile
# at this point we should have a valid reusable built cache that only changes
# when either deps or config/{config,prod}.exs change

COPY priv priv
COPY lib lib
COPY config/runtime.exs config/
# COPY rel rel # could contain rel/vm.args.eex, rel/remote.vm.args.eex, and rel/env.sh.eex
RUN mix release

FROM alpine:3.19.1 as app

RUN apk add --no-cache bash openssl libgcc libstdc++ ncurses-libs

RUN adduser -D app
COPY --from=app_builder /app/_build .
RUN chown -R app:app /prod
USER app
CMD ["./prod/rel/my_bot/bin/my_bot", "start"]
```

- `.dockerignore`
``` dockerfile
# flyctl launch added from .elixir_ls/.gitignore
.elixir_ls/**/*

# flyctl launch added from .gitignore
# The directory Mix will write compiled artifacts to.
_build

# If you run "mix test --cover", coverage assets end up here.
cover

# The directory Mix downloads your dependencies sources to.
deps

# Where third-party dependencies like ExDoc output generated docs.
doc

# Ignore .fetch files in case you like to edit your project deps locally.
.fetch

# If the VM crashes, it generates a dump, let's ignore it too.
**/erl_crash.dump

# Also ignore archive artifacts (built via "mix archive.build").
**/*.ez

# Ignore package tarball (built via "mix hex.build").
**/my_bot-*.tar

# Temporary files, for example, from tests.
tmp

# flyctl launch added from .lexical/.gitignore
.lexical/**/*
fly.toml
```


Now we'll execute `fly launch --no-deploy` to generate our base `fly.toml`.

``` shell
We're about to launch your app on Fly.io. Here's what you're getting:

Organization: <Name>                 (fly launch defaults to the personal org)
Name:         my-bot                 (derived from your directory name)
Region:       <Region>               (this is the fastest region for you)
App Machines: shared-cpu-1x, 1GB RAM (most apps need about 1GB of RAM)
Postgres:     <none>                 (not requested)
Redis:        <none>                 (not requested)
Sentry:       false                  (not requested)

? Do you want to tweak these settings before proceeding? (y/N)
```

We want to edit this values, let's select `y`, this will open a tab in your browser to finish configuring your application, the values that I have changed are:

- App name: Write whatever app name you want
- VM Memory: 256MB, I want to use the free tier, so I have to use the 256MB VMs
- Postgres: Setup a postgres database, pick whatever name you want, and select the "Development" configuration in order to have only one machine and keep it in the free tier.

That's all I changed, but feel free to tweak what you want.

Now I changed the `fly.toml` to only have one instance of my app instead of two, and to not stop the machines when idle, but you can keep it at two:

``` yaml
app = <your-app>
primary_region = <your-region>

[build]

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = false
  min_machines_running = 0
  processes = ['app']

[[vm]]
  size = 'shared-cpu-1x'
  count = 1
```

Now, everytime we want to deploy the application, we just need to run `fly deploy`.

## Updating the bot to webhook

If you have the bot setup to use polling, you can already deploy the application and it will work right away,
but if you want to use the benefit of having the application deployed, you will want to use the webhook mode to improve performance and use less resources.

For that, first we need to change the config files, I want to keep `polling` on development/testing and `webhook` will be used only on production.

- `config/config.exs`
``` elixir
import Config

config :ex_gram,
  method: :polling,
  adapter: ExGram.Adapter.Tesla,
  polling: [allowed_updates: []]

import_config "#{config_env()}.exs"
```

- `config/dev.exs`

``` elixir
import Config

config :ex_gram, token: "YOUR_BOT_TOKEN"
```

- `config/prod.exs`

``` elixir
import Config
```

- `config/runtime.exs`

``` elixir
import Config

if config_env() == :prod do
  config :ex_gram,
    token: System.get_env("BOT_TOKEN"),
    method: :webhook,
    adapter: ExGram.Adapter.Tesla,
    webhook: [
      allowed_updates: [],
      drop_pending_updates: false,
      max_connections: 50,
      secret_token: System.get_env("WEBHOOK_SECRET_TOKEN"),
      url: "https://#{System.get_env("FLY_APP_NAME")}.fly.dev/"
    ]
end
```

- `config/test.exs`

``` elixir
import Config

config :ex_gram, token: "NOTHING", adapter: ExGram.Adapter.Test, updates: ExGram.Updates.Test
```

The webhook configuration is on `runtime.exs`, and we can see that we are using two environment variables, let's set them up in our Fly application:

``` shen
fly secrets set BOT_TOKEN=YOUR_BOT_TOKEN --stage
fly secrets set WEBHOOK_SECRET_TOKEN=WHATEVER_SECRET_TOKEN_YOU_WANT --stage
```

Now we need to add a couple of dependencies to listen on the port we want and setup the webhook plug.

- `mix.exs`
``` elixir
# ...

  defp deps do
    [
      # ...
      # Add this two:
      {:plug_cowboy, "~> 2.7"},
      {:plug, "~> 1.15"}
    ]
  end
```

We need to create a router, and plug the `ExGram.Plug` to route the updates:

- `lib/my_bot/router.ex`

``` elixir
defmodule MyBot.Router do
  use Plug.Router

  plug(ExGram.Plug)

  plug(:match)
  plug(:dispatch)

  get("/", do: send_resp(conn, 200, "Welcome"))
  match(_, do: send_resp(conn, 404, "Oops, wrong path!"))
end
```

And finally we just need to update our `application.ex` to add the router and get the new config

- `lib/my_bot/application.ex`

``` elixir

  @impl true
  def start(_type, _args) do
    token = Application.get_env(:ex_gram, :token)
    method = Application.get_env(:ex_gram, :method)

    children = [
      ExGram,
      {MyBot.Bot, method: method, token: token},
      {Plug.Cowboy, scheme: :http, plug: MyBot.Router, port: 8080}
    ]

    opts = [strategy: :one_for_one, name: MyBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
```
