defmodule Telex do
  use Supervisor

  use Maxwell.Builder, ~w(get post)a
  import Telex.Macros
  import Telex.Model

  middleware Maxwell.Middleware.BaseUrl, "https://api.telegram.org"
  middleware Maxwell.Middleware.Headers, %{"Content-Type" => "application/json"}
  middleware Maxwell.Middleware.Opts, [connect_timeout: 5000, recv_timeout: 30000]
  middleware Maxwell.Middleware.Json, [decode_func: &Telex.custom_decode/1]
  # middleware Maxwell.Middleware.Json
  # middleware Telex.Middleware, Config.get(:telex, :token, "<TOKEN>")
  # middleware Maxwell.Middleware.Logger

  adapter Maxwell.Adapter.Hackney

  def custom_decode(x), do: Poison.Parser.parse(x, keys: :atoms)

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      supervisor(Registry, [:unique, Registry.Telex])
    ]

    supervise(children, strategy: :one_for_one)
  end

  # AUTO GENERATED

  method :get, "getUpdates", [{offset, [:integer], :optional}, {limit, [:integer], :optional}, {timeout, [:integer], :optional}, {allowed_updates, [{:array, :string}], :optional}], [Telex.Model.Update]

  method :post, "setWebhook", [{url, [:string]}, {certificate, [:file], :optional}, {max_connections, [:integer], :optional}, {allowed_updates, [{:array, :string}], :optional}], true

  method :post, "deleteWebhook", [], true

  method :get, "getWebhookInfo", [], Telex.Model.WebhookInfo

  method :get, "getMe", [], Telex.Model.User

  method :post, "sendMessage", [{chat_id, [:integer, :string]}, {text, [:string]}, {parse_mode, [:string], :optional}, {disable_web_page_preview, [:boolean], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "forwardMessage", [{chat_id, [:integer, :string]}, {from_chat_id, [:integer, :string]}, {disable_notification, [:boolean], :optional}, {message_id, [:integer]}], Telex.Model.Message

  method :post, "sendPhoto", [{chat_id, [:integer, :string]}, {photo, [:file, :string]}, {caption, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendAudio", [{chat_id, [:integer, :string]}, {audio, [:file, :string]}, {caption, [:string], :optional}, {duration, [:integer], :optional}, {performer, [:string], :optional}, {title, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendDocument", [{chat_id, [:integer, :string]}, {document, [:file, :string]}, {caption, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendSticker", [{chat_id, [:integer, :string]}, {sticker, [:file, :string]}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendVideo", [{chat_id, [:integer, :string]}, {video, [:file, :string]}, {duration, [:integer], :optional}, {width, [:integer], :optional}, {height, [:integer], :optional}, {caption, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendVoice", [{chat_id, [:integer, :string]}, {voice, [:file, :string]}, {caption, [:string], :optional}, {duration, [:integer], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendLocation", [{chat_id, [:integer, :string]}, {latitude, [:float]}, {longitude, [:float]}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendVenue", [{chat_id, [:integer, :string]}, {latitude, [:float]}, {longitude, [:float]}, {title, [:string]}, {address, [:string]}, {foursquare_id, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendContact", [{chat_id, [:integer, :string]}, {phone_number, [:string]}, {first_name, [:string]}, {last_name, [:string], :optional}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}], Telex.Model.Message

  method :post, "sendChatAction", [{chat_id, [:integer, :string]}, {action, [:string]}], true

  method :get, "getUserProfilePhotos", [{user_id, [:integer]}, {offset, [:integer], :optional}, {limit, [:integer], :optional}], Telex.Model.UserProfilePhotos

  method :get, "getFile", [{file_id, [:string]}], Telex.Model.File

  method :post, "kickChatMember", [{chat_id, [:integer, :string]}, {user_id, [:integer]}], true

  method :post, "leaveChat", [{chat_id, [:integer, :string]}], true

  method :post, "unbanChatMember", [{chat_id, [:integer, :string]}, {user_id, [:integer]}], true

  method :get, "getChat", [{chat_id, [:integer, :string]}], Telex.Model.Chat

  method :get, "getChatAdministrators", [{chat_id, [:integer, :string]}], [Telex.Model.ChatMember]

  method :get, "getChatMembersCount", [{chat_id, [:integer, :string]}], integer

  method :get, "getChatMember", [{chat_id, [:integer, :string]}, {user_id, [:integer]}], Telex.Model.ChatMember

  method :post, "answerCallbackQuery", [{callback_query_id, [:string]}, {text, [:string], :optional}, {show_alert, [:boolean], :optional}, {url, [:string], :optional}, {cache_time, [:integer], :optional}], true

  method :post, "editMessageText", [{chat_id, [:integer, :string], :optional}, {message_id, [:integer], :optional}, {inline_message_id, [:string], :optional}, {text, [:string]}, {parse_mode, [:string], :optional}, {disable_web_page_preview, [:boolean], :optional}, {reply_markup, [InlineKeyboardMarkup], :optional}], Telex.Model.Message

  method :post, "editMessageCaption", [{chat_id, [:integer, :string], :optional}, {message_id, [:integer], :optional}, {inline_message_id, [:string], :optional}, {caption, [:string], :optional}, {reply_markup, [InlineKeyboardMarkup], :optional}], Telex.Model.Message

  method :post, "editMessageReplyMarkup", [{chat_id, [:integer, :string], :optional}, {message_id, [:integer], :optional}, {inline_message_id, [:string], :optional}, {reply_markup, [InlineKeyboardMarkup], :optional}], Telex.Model.Message

  method :post, "answerInlineQuery", [{inline_query_id, [:string]}, {results, [{:array, InlineQueryResult}]}, {cache_time, [:integer], :optional}, {is_personal, [:boolean], :optional}, {next_offset, [:string], :optional}, {switch_pm_text, [:string], :optional}, {switch_pm_parameter, [:string], :optional}], true

  method :post, "sendGame", [{chat_id, [:integer]}, {game_short_name, [:string]}, {disable_notification, [:boolean], :optional}, {reply_to_message_id, [:integer], :optional}, {reply_markup, [InlineKeyboardMarkup], :optional}], Telex.Model.Message

  method :post, "setGameScore", [{user_id, [:integer]}, {score, [:integer]}, {force, [:boolean], :optional}, {disable_edit_message, [:boolean], :optional}, {chat_id, [:integer], :optional}, {message_id, [:integer], :optional}, {inline_message_id, [:string], :optional}], Telex.Model.Message

  method :get, "getGameHighScores", [{user_id, [:integer]}, {chat_id, [:integer], :optional}, {message_id, [:integer], :optional}, {inline_message_id, [:string], :optional}], [Telex.Model.GameHighScore]
end
