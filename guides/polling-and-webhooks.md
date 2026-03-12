# Polling and Webhooks

ExGram supports two methods for receiving updates from Telegram: **Polling** and **Webhooks**.

## Polling Mode

Polling is the easiest way to get your bot running. The bot periodically calls `getUpdates` on the Telegram Bot API to retrieve new messages.

**Best for:**
- Development and testing
- Simple deployments
- Bots that don't need instant responses
- Environments where you can't expose a public URL

### Basic Polling Setup

```elixir
# In your application supervision tree
children = [
  ExGram,
  {MyBot, [method: :polling, token: "YOUR_TOKEN"]}
]
```

### Configuring `allowed_updates`

By default, Telegram sends all update types. You can filter to only the types you need:

**In supervision tree:**

```elixir
{MyBot, [
  method: {:polling, allowed_updates: ["message", "edited_message", "callback_query"]},
  token: "YOUR_TOKEN"
]}
```

**In application config:**

```elixir
config :ex_gram, :polling,
  allowed_updates: ["message", "edited_message", "callback_query"]
```

Supervision tree options override config file settings, allowing per-bot customization.

### Available Update Types

- `"message"` - New incoming messages
- `"edited_message"` - Edited messages
- `"channel_post"` - Channel posts
- `"edited_channel_post"` - Edited channel posts
- `"inline_query"` - Inline queries
- `"chosen_inline_result"` - Inline query results chosen by user
- `"callback_query"` - Callback button presses
- `"shipping_query"` - Shipping query for payments
- `"pre_checkout_query"` - Pre-checkout query for payments
- `"poll"` - Poll state updates
- `"poll_answer"` - User's poll answer

### Webhook Cleanup

By default, polling mode deletes any existing webhook. If you've never used webhooks, you can skip this:

```elixir
config :ex_gram, :polling,
  allowed_updates: ["message"],
  delete_webhook: false
```

## Webhook Mode

Webhooks provide real-time updates. Telegram sends updates to your server via HTTP POST requests.

**Best for:**
- Production deployments
- Bots requiring instant responses
- High-traffic bots
- Efficient resource usage

### Prerequisites

1. A public HTTPS URL (HTTP not supported by Telegram)
2. Valid SSL certificate (self-signed works)
3. `Plug` and `plug_cowboy` dependencies

### Setup

**1. Add dependencies:**

```elixir
def deps do
  [
    # ... other deps
    {:plug_cowboy, "~> 2.0"},
    {:plug, "~> 1.0"}
  ]
end
```

**2. Add `ExGram.Plug` to your router:**

```elixir
defmodule MyApp.Router do
  use Plug.Router

  plug ExGram.Plug
  
  # Your other routes...
end
```

The webhook endpoint will be at `/telegram/<bot_token_hash>` or you can configure your custom path in the configuration, see Webhook Configuration section

**3. Configure your bot:**

```elixir
children = [
  ExGram,
  {MyBot, [method: :webhook, token: "YOUR_TOKEN"]}
]
```

### Webhook Configuration

#### In Config File

If you configure your webhook options globally, all your bots using webhook will use the same configuration, but they will be independent.

```elixir
config :ex_gram, :webhook,
  url: "https://bot.example.com",
  path: "/your/own/path",
  allowed_updates: ["message", "callback_query"],
  certificate: "priv/cert/selfsigned.pem",
  drop_pending_updates: false,
  ip_address: "1.1.1.1",
  max_connections: 50,
  secret_token: "your_secret_here"
```

#### In Supervision Tree

You can configure it on the supervision tree instead of the global config, to have different configurations per bot for example. 

If you configure it this way, and setup a custom path, you have to also configure the plug to use that path.

```elixir
# application.ex
webhook_options = [
  url: "https://bot.example.com",
  path: "/custom/path",
  allowed_updates: ["message", "callback_query"],
  secret_token: System.get_env("WEBHOOK_SECRET")
]

children = [
  ExGram,
  {MyBot, [method: {:webhook, webhook_options}, token: "YOUR_TOKEN"]}
]

# router.ex
plug ExGram.Plug, path: "/custom/path"
```

### Webhook Options

| Option | Type | Description |
|--------|------|-------------|
| `url` | String | **Required.** Your bot's public HTTPS URL (with scheme and optional port) |
| `path` | String | The path that will be used as a callback. If not provided `"/telegram"` is used. |
| `allowed_updates` | List of strings | Update types to receive (same as polling) |
| `certificate` | String | Path to self-signed certificate file |
| `drop_pending_updates` | Boolean | Drop updates that arrived while bot was down |
| `ip_address` | String | Fixed IP address for Telegram to use |
| `max_connections` | Integer | Max simultaneous connections (1-100, default 40) |
| `secret_token` | String | Secret token to verify requests are from Telegram |

See [Telegram setWebhook docs](https://core.telegram.org/bots/api#setwebhook) for detailed explanations.

### Using Self-Signed Certificates

For development or internal deployments:

```elixir
config :ex_gram, :webhook,
  url: "https://bot.example.com:8443",
  certificate: "priv/cert/selfsigned.pem"
```

Generate a self-signed certificate:

```bash
openssl req -newkey rsa:2048 -sha256 -nodes -keyout private.key -x509 -days 365 -out cert.pem
```

### Secret Token Verification

Add a secret token for additional security:

```elixir
config :ex_gram, :webhook,
  url: "https://bot.example.com",
  secret_token: System.get_env("WEBHOOK_SECRET_TOKEN")
```

Telegram will send this token in the `X-Telegram-Bot-Api-Secret-Token` header.

## Test Environment

Telegram provides a [Test Environment](https://core.telegram.org/bots/webapps#using-bots-in-the-test-environment) for testing your bot without affecting production.

Enable it in config:

```elixir
config :ex_gram, test_environment: true
```

**Note:** You'll need a separate bot token from the test environment's BotFather.

## Choosing Between Polling and Webhooks

| Feature | Polling | Webhooks |
|---------|---------|----------|
| Setup complexity | Simple | Moderate (requires HTTPS) |
| Real-time updates | Delayed (polling interval) | Instant |
| Server requirements | None | Public HTTPS endpoint |
| Resource usage | Constant (polling loop) | On-demand (per update) |
| Best for | Development, simple bots | Production, high-traffic |
| Network | Works behind firewall/NAT | Requires public IP |

## Multiple Bots with Different Methods

You can run different bots with different update methods:

```elixir
children = [
  ExGram,
  {MyBot.DevBot, [method: :polling, token: dev_token]},
  {MyBot.ProdBot, [method: :webhook, token: prod_token]},
  {MyBot.OtherBot, [method: :webhook, token: other_token]}
]
```

See [Multiple Bots](multiple-bots.md) for more details.

## Next Steps

- [Sending Messages](sending-messages.md) - Learn the DSL for building responses
- [Multiple Bots](multiple-bots.md) - Run multiple bots in one application
- [Fly.io Deployment](flyio.md) - Deploy your webhook bot to production
