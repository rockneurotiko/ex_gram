defmodule ExGram do
  @moduledoc """
  ExGram main supervisor that starts the bot's registry.

  All the API calls are in this module. The API method's and models are auto generated and uses macros to build them.
  """

  use Supervisor

  import ExGram.Macros

  def start_link(opts \\ []) do
    name = opts[:name] || __MODULE__

    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    reload_engine()

    children = [
      {Registry, [keys: :unique, name: Registry.ExGram]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp reload_engine() do
    engine = Application.get_env(:ex_gram, :json_engine)
    ExGram.Encoder.EngineCompiler.compile(engine)
  end

  # ----------METHODS-----------

  # AUTO GENERATED

  # Methods

  method(
    :get,
    "getUpdates",
    [
      {offset, [:integer], :optional},
      {limit, [:integer], :optional},
      {timeout, [:integer], :optional},
      {allowed_updates, [{:array, :string}], :optional}
    ],
    [ExGram.Model.Update]
  )

  method(
    :post,
    "setWebhook",
    [
      {url, [:string]},
      {certificate, [:file], :optional},
      {ip_address, [:string], :optional},
      {max_connections, [:integer], :optional},
      {allowed_updates, [{:array, :string}], :optional},
      {drop_pending_updates, [:boolean], :optional}
    ],
    true
  )

  method(:post, "deleteWebhook", [], true)

  method(:get, "getWebhookInfo", [], ExGram.Model.WebhookInfo)

  method(:get, "getMe", [], ExGram.Model.User)

  method(
    :post,
    "logOut",
    [
      {chat_id, [:integer, :string]},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {entities, [{:array, MessageEntity}], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    true
  )

  method(
    :post,
    "close",
    [
      {chat_id, [:integer, :string]},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {entities, [{:array, MessageEntity}], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    true
  )

  method(
    :post,
    "sendMessage",
    [
      {chat_id, [:integer, :string]},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {entities, [{:array, MessageEntity}], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "forwardMessage",
    [
      {chat_id, [:integer, :string]},
      {from_chat_id, [:integer, :string]},
      {disable_notification, [:boolean], :optional},
      {message_id, [:integer]}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "copyMessage",
    [
      {chat_id, [:integer, :string]},
      {from_chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.MessageId
  )

  method(
    :post,
    "sendPhoto",
    [
      {chat_id, [:integer, :string]},
      {photo, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendAudio",
    [
      {chat_id, [:integer, :string]},
      {audio, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {duration, [:integer], :optional},
      {performer, [:string], :optional},
      {title, [:string], :optional},
      {thumb, [:file, :string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendDocument",
    [
      {chat_id, [:integer, :string]},
      {document, [:file, :string]},
      {thumb, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_content_type_detection, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendVideo",
    [
      {chat_id, [:integer, :string]},
      {video, [:file, :string]},
      {duration, [:integer], :optional},
      {width, [:integer], :optional},
      {height, [:integer], :optional},
      {thumb, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {supports_streaming, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendAnimation",
    [
      {chat_id, [:integer, :string]},
      {animation, [:file, :string]},
      {duration, [:integer], :optional},
      {width, [:integer], :optional},
      {height, [:integer], :optional},
      {thumb, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendVoice",
    [
      {chat_id, [:integer, :string]},
      {voice, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {duration, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendVideoNote",
    [
      {chat_id, [:integer, :string]},
      {video_note, [:file, :string]},
      {duration, [:integer], :optional},
      {length, [:integer], :optional},
      {thumb, [:file, :string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendMediaGroup",
    [
      {chat_id, [:integer, :string]},
      {media,
       [{:array, [InputMediaAudio, InputMediaDocument, InputMediaPhoto, InputMediaVideo]}]},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional}
    ],
    [ExGram.Model.Message]
  )

  method(
    :post,
    "sendLocation",
    [
      {chat_id, [:integer, :string]},
      {latitude, [:float]},
      {longitude, [:float]},
      {horizontal_accuracy, [:float], :optional},
      {live_period, [:integer], :optional},
      {heading, [:integer], :optional},
      {proximity_alert_radius, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "editMessageLiveLocation",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {latitude, [:float]},
      {longitude, [:float]},
      {horizontal_accuracy, [:float], :optional},
      {heading, [:integer], :optional},
      {proximity_alert_radius, [:integer], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "stopMessageLiveLocation",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendVenue",
    [
      {chat_id, [:integer, :string]},
      {latitude, [:float]},
      {longitude, [:float]},
      {title, [:string]},
      {address, [:string]},
      {foursquare_id, [:string], :optional},
      {foursquare_type, [:string], :optional},
      {google_place_id, [:string], :optional},
      {google_place_type, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendContact",
    [
      {chat_id, [:integer, :string]},
      {phone_number, [:string]},
      {first_name, [:string]},
      {last_name, [:string], :optional},
      {vcard, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendPoll",
    [
      {chat_id, [:integer, :string]},
      {question, [:string]},
      {options, [{:array, :string}]},
      {is_anonymous, [:boolean], :optional},
      {type, [:string], :optional},
      {allows_multiple_answers, [:boolean], :optional},
      {correct_option_id, [:integer], :optional},
      {explanation, [:string], :optional},
      {explanation_parse_mode, [:string], :optional},
      {explanation_entities, [{:array, MessageEntity}], :optional},
      {open_period, [:integer], :optional},
      {close_date, [:integer], :optional},
      {is_closed, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "sendDice",
    [
      {chat_id, [:integer, :string]},
      {emoji, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(:post, "sendChatAction", [{chat_id, [:integer, :string]}, {action, [:string]}], true)

  method(
    :get,
    "getUserProfilePhotos",
    [{user_id, [:integer]}, {offset, [:integer], :optional}, {limit, [:integer], :optional}],
    ExGram.Model.UserProfilePhotos
  )

  method(:get, "getFile", [{file_id, [:string]}], ExGram.Model.File)

  method(
    :post,
    "banChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {until_date, [:integer], :optional},
      {revoke_messages, [:boolean], :optional}
    ],
    true
  )

  method(
    :post,
    "unbanChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {only_if_banned, [:boolean], :optional}
    ],
    true
  )

  method(
    :post,
    "restrictChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {permissions, [ChatPermissions]},
      {until_date, [:integer], :optional}
    ],
    true
  )

  method(
    :post,
    "promoteChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {is_anonymous, [:boolean], :optional},
      {can_manage_chat, [:boolean], :optional},
      {can_post_messages, [:boolean], :optional},
      {can_edit_messages, [:boolean], :optional},
      {can_delete_messages, [:boolean], :optional},
      {can_manage_voice_chats, [:boolean], :optional},
      {can_restrict_members, [:boolean], :optional},
      {can_promote_members, [:boolean], :optional},
      {can_change_info, [:boolean], :optional},
      {can_invite_users, [:boolean], :optional},
      {can_pin_messages, [:boolean], :optional}
    ],
    true
  )

  method(
    :post,
    "setChatAdministratorCustomTitle",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}, {custom_title, [:string]}],
    true
  )

  method(
    :post,
    "setChatPermissions",
    [{chat_id, [:integer, :string]}, {permissions, [ChatPermissions]}],
    true
  )

  method(:post, "exportChatInviteLink", [{chat_id, [:integer, :string]}], :string)

  method(
    :post,
    "createChatInviteLink",
    [
      {chat_id, [:integer, :string]},
      {expire_date, [:integer], :optional},
      {member_limit, [:integer], :optional}
    ],
    ExGram.Model.ChatInviteLink
  )

  method(
    :post,
    "editChatInviteLink",
    [
      {chat_id, [:integer, :string]},
      {invite_link, [:string]},
      {expire_date, [:integer], :optional},
      {member_limit, [:integer], :optional}
    ],
    ExGram.Model.ChatInviteLink
  )

  method(
    :post,
    "revokeChatInviteLink",
    [{chat_id, [:integer, :string]}, {invite_link, [:string]}],
    ExGram.Model.ChatInviteLink
  )

  method(:post, "setChatPhoto", [{chat_id, [:integer, :string]}, {photo, [:file]}], true)

  method(:post, "deleteChatPhoto", [{chat_id, [:integer, :string]}], true)

  method(:post, "setChatTitle", [{chat_id, [:integer, :string]}, {title, [:string]}], true)

  method(
    :post,
    "setChatDescription",
    [{chat_id, [:integer, :string]}, {description, [:string], :optional}],
    true
  )

  method(
    :post,
    "pinChatMessage",
    [
      {chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {disable_notification, [:boolean], :optional}
    ],
    true
  )

  method(
    :post,
    "unpinChatMessage",
    [{chat_id, [:integer, :string]}, {message_id, [:integer], :optional}],
    true
  )

  method(:post, "unpinAllChatMessages", [{chat_id, [:integer, :string]}], true)

  method(:post, "leaveChat", [{chat_id, [:integer, :string]}], true)

  method(:get, "getChat", [{chat_id, [:integer, :string]}], ExGram.Model.Chat)

  method(:get, "getChatAdministrators", [{chat_id, [:integer, :string]}], [
    ExGram.Model.ChatMember
  ])

  method(:get, "getChatMemberCount", [{chat_id, [:integer, :string]}], :integer)

  method(
    :get,
    "getChatMember",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}],
    ExGram.Model.ChatMember
  )

  method(
    :post,
    "setChatStickerSet",
    [{chat_id, [:integer, :string]}, {sticker_set_name, [:string]}],
    true
  )

  method(:post, "deleteChatStickerSet", [{chat_id, [:integer, :string]}], true)

  method(
    :post,
    "answerCallbackQuery",
    [
      {callback_query_id, [:string]},
      {text, [:string], :optional},
      {show_alert, [:boolean], :optional},
      {url, [:string], :optional},
      {cache_time, [:integer], :optional}
    ],
    true
  )

  method(
    :post,
    "setMyCommands",
    [
      {commands, [{:array, BotCommand}]},
      {scope, [BotCommandScope], :optional},
      {language_code, [:string], :optional}
    ],
    true
  )

  method(
    :post,
    "deleteMyCommands",
    [{scope, [BotCommandScope], :optional}, {language_code, [:string], :optional}],
    true
  )

  method(:get, "getMyCommands", [], [ExGram.Model.BotCommand])

  method(
    :post,
    "editMessageText",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {entities, [{:array, MessageEntity}], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "editMessageCaption",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "editMessageMedia",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {media, [InputMedia]},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "editMessageReplyMarkup",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "stopPoll",
    [
      {chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Poll
  )

  method(:post, "deleteMessage", [{chat_id, [:integer, :string]}, {message_id, [:integer]}], true)

  method(
    :post,
    "sendSticker",
    [
      {chat_id, [:integer, :string]},
      {sticker, [:file, :string]},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(:get, "getStickerSet", [{name, [:string]}], ExGram.Model.StickerSet)

  method(
    :post,
    "uploadStickerFile",
    [{user_id, [:integer]}, {png_sticker, [:file]}],
    ExGram.Model.File
  )

  method(
    :post,
    "createNewStickerSet",
    [
      {user_id, [:integer]},
      {name, [:string]},
      {title, [:string]},
      {png_sticker, [:file, :string], :optional},
      {tgs_sticker, [:file], :optional},
      {emojis, [:string]},
      {contains_masks, [:boolean], :optional},
      {mask_position, [MaskPosition], :optional}
    ],
    true
  )

  method(
    :post,
    "addStickerToSet",
    [
      {user_id, [:integer]},
      {name, [:string]},
      {png_sticker, [:file, :string], :optional},
      {tgs_sticker, [:file], :optional},
      {emojis, [:string]},
      {mask_position, [MaskPosition], :optional}
    ],
    true
  )

  method(:post, "setStickerPositionInSet", [{sticker, [:string]}, {position, [:integer]}], true)

  method(:post, "deleteStickerFromSet", [{sticker, [:string]}], true)

  method(
    :post,
    "setStickerSetThumb",
    [{name, [:string]}, {user_id, [:integer]}, {thumb, [:file, :string], :optional}],
    true
  )

  method(
    :post,
    "answerInlineQuery",
    [
      {inline_query_id, [:string]},
      {results, [{:array, InlineQueryResult}]},
      {cache_time, [:integer], :optional},
      {is_personal, [:boolean], :optional},
      {next_offset, [:string], :optional},
      {switch_pm_text, [:string], :optional},
      {switch_pm_parameter, [:string], :optional}
    ],
    true
  )

  method(
    :post,
    "sendInvoice",
    [
      {chat_id, [:integer, :string]},
      {title, [:string]},
      {description, [:string]},
      {payload, [:string]},
      {provider_token, [:string]},
      {currency, [:string]},
      {prices, [{:array, LabeledPrice}]},
      {max_tip_amount, [:integer], :optional},
      {suggested_tip_amounts, [{:array, :integer}], :optional},
      {start_parameter, [:string], :optional},
      {provider_data, [:string], :optional},
      {photo_url, [:string], :optional},
      {photo_size, [:integer], :optional},
      {photo_width, [:integer], :optional},
      {photo_height, [:integer], :optional},
      {need_name, [:boolean], :optional},
      {need_phone_number, [:boolean], :optional},
      {need_email, [:boolean], :optional},
      {need_shipping_address, [:boolean], :optional},
      {send_phone_number_to_provider, [:boolean], :optional},
      {send_email_to_provider, [:boolean], :optional},
      {is_flexible, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "answerShippingQuery",
    [
      {shipping_query_id, [:string]},
      {ok, [:boolean]},
      {shipping_options, [{:array, ShippingOption}], :optional},
      {error_message, [:string], :optional}
    ],
    true
  )

  method(
    :post,
    "answerPreCheckoutQuery",
    [{pre_checkout_query_id, [:string]}, {ok, [:boolean]}, {error_message, [:string], :optional}],
    true
  )

  method(
    :post,
    "setPassportDataErrors",
    [{user_id, [:integer]}, {errors, [{:array, PassportElementError}]}],
    true
  )

  method(
    :post,
    "sendGame",
    [
      {chat_id, [:integer]},
      {game_short_name, [:string]},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :post,
    "setGameScore",
    [
      {user_id, [:integer]},
      {score, [:integer]},
      {force, [:boolean], :optional},
      {disable_edit_message, [:boolean], :optional},
      {chat_id, [:integer], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional}
    ],
    ExGram.Model.Message
  )

  method(
    :get,
    "getGameHighScores",
    [
      {user_id, [:integer]},
      {chat_id, [:integer], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional}
    ],
    [ExGram.Model.GameHighScore]
  )

  # 78 methods

  # ----------MODELS-----------

  # Models

  defmodule Model do
    @moduledoc """
    Telegram API Model structures
    """

    model(Update, [
      {:update_id, :integer},
      {:message, Message, :optional},
      {:edited_message, Message, :optional},
      {:channel_post, Message, :optional},
      {:edited_channel_post, Message, :optional},
      {:inline_query, InlineQuery, :optional},
      {:chosen_inline_result, ChosenInlineResult, :optional},
      {:callback_query, CallbackQuery, :optional},
      {:shipping_query, ShippingQuery, :optional},
      {:pre_checkout_query, PreCheckoutQuery, :optional},
      {:poll, Poll, :optional},
      {:poll_answer, PollAnswer, :optional},
      {:my_chat_member, ChatMemberUpdated, :optional},
      {:chat_member, ChatMemberUpdated, :optional}
    ])

    model(WebhookInfo, [
      {:url, :string},
      {:has_custom_certificate, :boolean},
      {:pending_update_count, :integer},
      {:ip_address, :string, :optional},
      {:last_error_date, :integer, :optional},
      {:last_error_message, :string, :optional},
      {:max_connections, :integer, :optional},
      {:allowed_updates, {:array, :string}, :optional}
    ])

    model(User, [
      {:id, :integer},
      {:is_bot, :boolean},
      {:first_name, :string},
      {:last_name, :string, :optional},
      {:username, :string, :optional},
      {:language_code, :string, :optional},
      {:can_join_groups, :boolean, :optional},
      {:can_read_all_group_messages, :boolean, :optional},
      {:supports_inline_queries, :boolean, :optional}
    ])

    model(Chat, [
      {:id, :integer},
      {:type, :string},
      {:title, :string, :optional},
      {:username, :string, :optional},
      {:first_name, :string, :optional},
      {:last_name, :string, :optional},
      {:photo, ChatPhoto, :optional},
      {:bio, :string, :optional},
      {:description, :string, :optional},
      {:invite_link, :string, :optional},
      {:pinned_message, Message, :optional},
      {:permissions, ChatPermissions, :optional},
      {:slow_mode_delay, :integer, :optional},
      {:message_auto_delete_time, :integer, :optional},
      {:sticker_set_name, :string, :optional},
      {:can_set_sticker_set, :boolean, :optional},
      {:linked_chat_id, :integer, :optional},
      {:location, ChatLocation, :optional}
    ])

    model(Message, [
      {:message_id, :integer},
      {:from, User, :optional},
      {:sender_chat, Chat, :optional},
      {:date, :integer},
      {:chat, Chat},
      {:forward_from, User, :optional},
      {:forward_from_chat, Chat, :optional},
      {:forward_from_message_id, :integer, :optional},
      {:forward_signature, :string, :optional},
      {:forward_sender_name, :string, :optional},
      {:forward_date, :integer, :optional},
      {:reply_to_message, Message, :optional},
      {:via_bot, User, :optional},
      {:edit_date, :integer, :optional},
      {:media_group_id, :string, :optional},
      {:author_signature, :string, :optional},
      {:text, :string, :optional},
      {:entities, {:array, MessageEntity}, :optional},
      {:animation, Animation, :optional},
      {:audio, Audio, :optional},
      {:document, Document, :optional},
      {:photo, {:array, PhotoSize}, :optional},
      {:sticker, Sticker, :optional},
      {:video, Video, :optional},
      {:video_note, VideoNote, :optional},
      {:voice, Voice, :optional},
      {:caption, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:contact, Contact, :optional},
      {:dice, Dice, :optional},
      {:game, Game, :optional},
      {:poll, Poll, :optional},
      {:venue, Venue, :optional},
      {:location, Location, :optional},
      {:new_chat_members, {:array, User}, :optional},
      {:left_chat_member, User, :optional},
      {:new_chat_title, :string, :optional},
      {:new_chat_photo, {:array, PhotoSize}, :optional},
      {:delete_chat_photo, :boolean, :optional},
      {:group_chat_created, :boolean, :optional},
      {:supergroup_chat_created, :boolean, :optional},
      {:channel_chat_created, :boolean, :optional},
      {:message_auto_delete_timer_changed, MessageAutoDeleteTimerChanged, :optional},
      {:migrate_to_chat_id, :integer, :optional},
      {:migrate_from_chat_id, :integer, :optional},
      {:pinned_message, Message, :optional},
      {:invoice, Invoice, :optional},
      {:successful_payment, SuccessfulPayment, :optional},
      {:connected_website, :string, :optional},
      {:passport_data, PassportData, :optional},
      {:proximity_alert_triggered, ProximityAlertTriggered, :optional},
      {:voice_chat_scheduled, VoiceChatScheduled, :optional},
      {:voice_chat_started, VoiceChatStarted, :optional},
      {:voice_chat_ended, VoiceChatEnded, :optional},
      {:voice_chat_participants_invited, VoiceChatParticipantsInvited, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional}
    ])

    model(MessageId, [{:message_id, :integer}])

    model(MessageEntity, [
      {:type, :string},
      {:offset, :integer},
      {:length, :integer},
      {:url, :string, :optional},
      {:user, User, :optional},
      {:language, :string, :optional}
    ])

    model(PhotoSize, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:file_size, :integer, :optional}
    ])

    model(Animation, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize, :optional},
      {:file_name, :string, :optional},
      {:mime_type, :string, :optional},
      {:file_size, :integer, :optional}
    ])

    model(Audio, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:duration, :integer},
      {:performer, :string, :optional},
      {:title, :string, :optional},
      {:file_name, :string, :optional},
      {:mime_type, :string, :optional},
      {:file_size, :integer, :optional},
      {:thumb, PhotoSize, :optional}
    ])

    model(Document, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:thumb, PhotoSize, :optional},
      {:file_name, :string, :optional},
      {:mime_type, :string, :optional},
      {:file_size, :integer, :optional}
    ])

    model(Video, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize, :optional},
      {:file_name, :string, :optional},
      {:mime_type, :string, :optional},
      {:file_size, :integer, :optional}
    ])

    model(VideoNote, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:length, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize, :optional},
      {:file_size, :integer, :optional}
    ])

    model(Voice, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:duration, :integer},
      {:mime_type, :string, :optional},
      {:file_size, :integer, :optional}
    ])

    model(Contact, [
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string, :optional},
      {:user_id, :integer, :optional},
      {:vcard, :string, :optional}
    ])

    model(Dice, [{:emoji, :string}, {:value, :integer}])

    model(PollOption, [{:text, :string}, {:voter_count, :integer}])

    model(PollAnswer, [{:poll_id, :string}, {:user, User}, {:option_ids, {:array, :integer}}])

    model(Poll, [
      {:id, :string},
      {:question, :string},
      {:options, {:array, PollOption}},
      {:total_voter_count, :integer},
      {:is_closed, :boolean},
      {:is_anonymous, :boolean},
      {:type, :string},
      {:allows_multiple_answers, :boolean},
      {:correct_option_id, :integer, :optional},
      {:explanation, :string, :optional},
      {:explanation_entities, {:array, MessageEntity}, :optional},
      {:open_period, :integer, :optional},
      {:close_date, :integer, :optional}
    ])

    model(Location, [
      {:longitude, :float},
      {:latitude, :float},
      {:horizontal_accuracy, :float, :optional},
      {:live_period, :integer, :optional},
      {:heading, :integer, :optional},
      {:proximity_alert_radius, :integer, :optional}
    ])

    model(Venue, [
      {:location, Location},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string, :optional},
      {:foursquare_type, :string, :optional},
      {:google_place_id, :string, :optional},
      {:google_place_type, :string, :optional}
    ])

    model(ProximityAlertTriggered, [{:traveler, User}, {:watcher, User}, {:distance, :integer}])

    model(MessageAutoDeleteTimerChanged, [{:message_auto_delete_time, :integer}])

    model(VoiceChatScheduled, [{:start_date, :integer}])

    model(VoiceChatStarted, [{:duration, :integer}])

    model(VoiceChatEnded, [{:duration, :integer}])

    model(VoiceChatParticipantsInvited, [{:users, {:array, User}, :optional}])

    model(UserProfilePhotos, [{:total_count, :integer}, {:photos, {:array, {:array, PhotoSize}}}])

    model(File, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:file_size, :integer, :optional},
      {:file_path, :string, :optional}
    ])

    model(ReplyKeyboardMarkup, [
      {:keyboard, {:array, {:array, KeyboardButton}}},
      {:resize_keyboard, :boolean, :optional},
      {:one_time_keyboard, :boolean, :optional},
      {:input_field_placeholder, :string, :optional},
      {:selective, :boolean, :optional}
    ])

    model(KeyboardButton, [
      {:text, :string},
      {:request_contact, :boolean, :optional},
      {:request_location, :boolean, :optional},
      {:request_poll, KeyboardButtonPollType, :optional}
    ])

    model(KeyboardButtonPollType, [{:type, :string, :optional}])

    model(ReplyKeyboardRemove, [{:remove_keyboard, :boolean}, {:selective, :boolean, :optional}])

    model(InlineKeyboardMarkup, [{:inline_keyboard, {:array, {:array, InlineKeyboardButton}}}])

    model(InlineKeyboardButton, [
      {:text, :string},
      {:url, :string, :optional},
      {:login_url, LoginUrl, :optional},
      {:callback_data, :string, :optional},
      {:switch_inline_query, :string, :optional},
      {:switch_inline_query_current_chat, :string, :optional},
      {:callback_game, CallbackGame, :optional},
      {:pay, :boolean, :optional}
    ])

    model(LoginUrl, [
      {:url, :string},
      {:forward_text, :string, :optional},
      {:bot_username, :string, :optional},
      {:request_write_access, :boolean, :optional}
    ])

    model(CallbackQuery, [
      {:id, :string},
      {:from, User},
      {:message, Message, :optional},
      {:inline_message_id, :string, :optional},
      {:chat_instance, :string},
      {:data, :string, :optional},
      {:game_short_name, :string, :optional}
    ])

    model(ForceReply, [
      {:force_reply, :boolean},
      {:input_field_placeholder, :string, :optional},
      {:selective, :boolean, :optional}
    ])

    model(ChatPhoto, [
      {:small_file_id, :string},
      {:small_file_unique_id, :string},
      {:big_file_id, :string},
      {:big_file_unique_id, :string}
    ])

    model(ChatInviteLink, [
      {:invite_link, :string},
      {:creator, User},
      {:is_primary, :boolean},
      {:is_revoked, :boolean},
      {:expire_date, :integer, :optional},
      {:member_limit, :integer, :optional}
    ])

    model(ChatMemberOwner, [
      {:status, :string},
      {:user, User},
      {:is_anonymous, :boolean},
      {:custom_title, :string, :optional}
    ])

    model(ChatMemberAdministrator, [
      {:status, :string},
      {:user, User},
      {:can_be_edited, :boolean},
      {:is_anonymous, :boolean},
      {:can_manage_chat, :boolean},
      {:can_delete_messages, :boolean},
      {:can_manage_voice_chats, :boolean},
      {:can_restrict_members, :boolean},
      {:can_promote_members, :boolean},
      {:can_change_info, :boolean},
      {:can_invite_users, :boolean},
      {:can_post_messages, :boolean, :optional},
      {:can_edit_messages, :boolean, :optional},
      {:can_pin_messages, :boolean, :optional},
      {:custom_title, :string, :optional}
    ])

    model(ChatMemberMember, [{:status, :string}, {:user, User}])

    model(ChatMemberRestricted, [
      {:status, :string},
      {:user, User},
      {:is_member, :boolean},
      {:can_change_info, :boolean},
      {:can_invite_users, :boolean},
      {:can_pin_messages, :boolean},
      {:can_send_messages, :boolean},
      {:can_send_media_messages, :boolean},
      {:can_send_polls, :boolean},
      {:can_send_other_messages, :boolean},
      {:can_add_web_page_previews, :boolean},
      {:until_date, :integer}
    ])

    model(ChatMemberLeft, [{:status, :string}, {:user, User}])

    model(ChatMemberBanned, [{:status, :string}, {:user, User}, {:until_date, :integer}])

    model(ChatMemberUpdated, [
      {:chat, Chat},
      {:from, User},
      {:date, :integer},
      {:old_chat_member, ChatMember},
      {:new_chat_member, ChatMember},
      {:invite_link, ChatInviteLink, :optional}
    ])

    model(ChatPermissions, [
      {:can_send_messages, :boolean, :optional},
      {:can_send_media_messages, :boolean, :optional},
      {:can_send_polls, :boolean, :optional},
      {:can_send_other_messages, :boolean, :optional},
      {:can_add_web_page_previews, :boolean, :optional},
      {:can_change_info, :boolean, :optional},
      {:can_invite_users, :boolean, :optional},
      {:can_pin_messages, :boolean, :optional}
    ])

    model(ChatLocation, [{:location, Location}, {:address, :string}])

    model(BotCommand, [{:command, :string}, {:description, :string}])

    model(BotCommandScopeDefault, [{:type, :string}])

    model(BotCommandScopeAllPrivateChats, [{:type, :string}])

    model(BotCommandScopeAllGroupChats, [{:type, :string}])

    model(BotCommandScopeAllChatAdministrators, [{:type, :string}])

    model(BotCommandScopeChat, [{:type, :string}, {:chat_id, :integer}])

    model(BotCommandScopeChatAdministrators, [{:type, :string}, {:chat_id, :integer}])

    model(BotCommandScopeChatMember, [
      {:type, :string},
      {:chat_id, :integer},
      {:user_id, :integer}
    ])

    model(ResponseParameters, [
      {:migrate_to_chat_id, :integer, :optional},
      {:retry_after, :integer, :optional}
    ])

    model(InputMedia, [
      {:type, :string},
      {:media, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional}
    ])

    model(InputMediaPhoto, [
      {:type, :string},
      {:media, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional}
    ])

    model(InputMediaVideo, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:width, :integer, :optional},
      {:height, :integer, :optional},
      {:duration, :integer, :optional},
      {:supports_streaming, :boolean, :optional}
    ])

    model(InputMediaAnimation, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:width, :integer, :optional},
      {:height, :integer, :optional},
      {:duration, :integer, :optional}
    ])

    model(InputMediaAudio, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:duration, :integer, :optional},
      {:performer, :string, :optional},
      {:title, :string, :optional}
    ])

    model(InputMediaDocument, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:disable_content_type_detection, :boolean, :optional}
    ])

    model(InputFile, [
      {:chat_id, :integer},
      {:text, :string},
      {:parse_mode, :string, :optional},
      {:entities, {:array, MessageEntity}, :optional},
      {:disable_web_page_preview, :boolean, :optional},
      {:disable_notification, :boolean, :optional},
      {:reply_to_message_id, :integer, :optional},
      {:allow_sending_without_reply, :boolean, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional}
    ])

    model(Sticker, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:is_animated, :boolean},
      {:thumb, PhotoSize, :optional},
      {:emoji, :string, :optional},
      {:set_name, :string, :optional},
      {:mask_position, MaskPosition, :optional},
      {:file_size, :integer, :optional}
    ])

    model(StickerSet, [
      {:name, :string},
      {:title, :string},
      {:is_animated, :boolean},
      {:contains_masks, :boolean},
      {:stickers, {:array, Sticker}},
      {:thumb, PhotoSize, :optional}
    ])

    model(MaskPosition, [
      {:point, :string},
      {:x_shift, :float},
      {:y_shift, :float},
      {:scale, :float}
    ])

    model(InlineQuery, [
      {:id, :string},
      {:from, User},
      {:query, :string},
      {:offset, :string},
      {:chat_type, :string, :optional},
      {:location, Location, :optional}
    ])

    model(InlineQueryResultArticle, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:input_message_content, InputMessageContent},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:url, :string, :optional},
      {:hide_url, :boolean, :optional},
      {:description, :string, :optional},
      {:thumb_url, :string, :optional},
      {:thumb_width, :integer, :optional},
      {:thumb_height, :integer, :optional}
    ])

    model(InlineQueryResultPhoto, [
      {:type, :string},
      {:id, :string},
      {:photo_url, :string},
      {:thumb_url, :string},
      {:photo_width, :integer, :optional},
      {:photo_height, :integer, :optional},
      {:title, :string, :optional},
      {:description, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultGif, [
      {:type, :string},
      {:id, :string},
      {:gif_url, :string},
      {:gif_width, :integer, :optional},
      {:gif_height, :integer, :optional},
      {:gif_duration, :integer, :optional},
      {:thumb_url, :string},
      {:thumb_mime_type, :string, :optional},
      {:title, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultMpeg4Gif, [
      {:type, :string},
      {:id, :string},
      {:mpeg4_url, :string},
      {:mpeg4_width, :integer, :optional},
      {:mpeg4_height, :integer, :optional},
      {:mpeg4_duration, :integer, :optional},
      {:thumb_url, :string},
      {:thumb_mime_type, :string, :optional},
      {:title, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultVideo, [
      {:type, :string},
      {:id, :string},
      {:video_url, :string},
      {:mime_type, :string},
      {:thumb_url, :string},
      {:title, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:video_width, :integer, :optional},
      {:video_height, :integer, :optional},
      {:video_duration, :integer, :optional},
      {:description, :string, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultAudio, [
      {:type, :string},
      {:id, :string},
      {:audio_url, :string},
      {:title, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:performer, :string, :optional},
      {:audio_duration, :integer, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultVoice, [
      {:type, :string},
      {:id, :string},
      {:voice_url, :string},
      {:title, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:voice_duration, :integer, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultDocument, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:document_url, :string},
      {:mime_type, :string},
      {:description, :string, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional},
      {:thumb_url, :string, :optional},
      {:thumb_width, :integer, :optional},
      {:thumb_height, :integer, :optional}
    ])

    model(InlineQueryResultLocation, [
      {:type, :string},
      {:id, :string},
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:horizontal_accuracy, :float, :optional},
      {:live_period, :integer, :optional},
      {:heading, :integer, :optional},
      {:proximity_alert_radius, :integer, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional},
      {:thumb_url, :string, :optional},
      {:thumb_width, :integer, :optional},
      {:thumb_height, :integer, :optional}
    ])

    model(InlineQueryResultVenue, [
      {:type, :string},
      {:id, :string},
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string, :optional},
      {:foursquare_type, :string, :optional},
      {:google_place_id, :string, :optional},
      {:google_place_type, :string, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional},
      {:thumb_url, :string, :optional},
      {:thumb_width, :integer, :optional},
      {:thumb_height, :integer, :optional}
    ])

    model(InlineQueryResultContact, [
      {:type, :string},
      {:id, :string},
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string, :optional},
      {:vcard, :string, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional},
      {:thumb_url, :string, :optional},
      {:thumb_width, :integer, :optional},
      {:thumb_height, :integer, :optional}
    ])

    model(InlineQueryResultGame, [
      {:type, :string},
      {:id, :string},
      {:game_short_name, :string},
      {:reply_markup, InlineKeyboardMarkup, :optional}
    ])

    model(InlineQueryResultCachedPhoto, [
      {:type, :string},
      {:id, :string},
      {:photo_file_id, :string},
      {:title, :string, :optional},
      {:description, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedGif, [
      {:type, :string},
      {:id, :string},
      {:gif_file_id, :string},
      {:title, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedMpeg4Gif, [
      {:type, :string},
      {:id, :string},
      {:mpeg4_file_id, :string},
      {:title, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedSticker, [
      {:type, :string},
      {:id, :string},
      {:sticker_file_id, :string},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedDocument, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:document_file_id, :string},
      {:description, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedVideo, [
      {:type, :string},
      {:id, :string},
      {:video_file_id, :string},
      {:title, :string},
      {:description, :string, :optional},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedVoice, [
      {:type, :string},
      {:id, :string},
      {:voice_file_id, :string},
      {:title, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InlineQueryResultCachedAudio, [
      {:type, :string},
      {:id, :string},
      {:audio_file_id, :string},
      {:caption, :string, :optional},
      {:parse_mode, :string, :optional},
      {:caption_entities, {:array, MessageEntity}, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional},
      {:input_message_content, InputMessageContent, :optional}
    ])

    model(InputTextMessageContent, [
      {:message_text, :string},
      {:parse_mode, :string, :optional},
      {:entities, {:array, MessageEntity}, :optional},
      {:disable_web_page_preview, :boolean, :optional}
    ])

    model(InputLocationMessageContent, [
      {:latitude, :float},
      {:longitude, :float},
      {:horizontal_accuracy, :float, :optional},
      {:live_period, :integer, :optional},
      {:heading, :integer, :optional},
      {:proximity_alert_radius, :integer, :optional}
    ])

    model(InputVenueMessageContent, [
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string, :optional},
      {:foursquare_type, :string, :optional},
      {:google_place_id, :string, :optional},
      {:google_place_type, :string, :optional}
    ])

    model(InputContactMessageContent, [
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string, :optional},
      {:vcard, :string, :optional}
    ])

    model(InputInvoiceMessageContent, [
      {:title, :string},
      {:description, :string},
      {:payload, :string},
      {:provider_token, :string},
      {:currency, :string},
      {:prices, {:array, LabeledPrice}},
      {:max_tip_amount, :integer, :optional},
      {:suggested_tip_amounts, {:array, :integer}, :optional},
      {:provider_data, :string, :optional},
      {:photo_url, :string, :optional},
      {:photo_size, :integer, :optional},
      {:photo_width, :integer, :optional},
      {:photo_height, :integer, :optional},
      {:need_name, :boolean, :optional},
      {:need_phone_number, :boolean, :optional},
      {:need_email, :boolean, :optional},
      {:need_shipping_address, :boolean, :optional},
      {:send_phone_number_to_provider, :boolean, :optional},
      {:send_email_to_provider, :boolean, :optional},
      {:is_flexible, :boolean, :optional}
    ])

    model(ChosenInlineResult, [
      {:result_id, :string},
      {:from, User},
      {:location, Location, :optional},
      {:inline_message_id, :string, :optional},
      {:query, :string}
    ])

    model(LabeledPrice, [{:label, :string}, {:amount, :integer}])

    model(Invoice, [
      {:title, :string},
      {:description, :string},
      {:start_parameter, :string},
      {:currency, :string},
      {:total_amount, :integer}
    ])

    model(ShippingAddress, [
      {:country_code, :string},
      {:state, :string},
      {:city, :string},
      {:street_line1, :string},
      {:street_line2, :string},
      {:post_code, :string}
    ])

    model(OrderInfo, [
      {:name, :string, :optional},
      {:phone_number, :string, :optional},
      {:email, :string, :optional},
      {:shipping_address, ShippingAddress, :optional}
    ])

    model(ShippingOption, [{:id, :string}, {:title, :string}, {:prices, {:array, LabeledPrice}}])

    model(SuccessfulPayment, [
      {:currency, :string},
      {:total_amount, :integer},
      {:invoice_payload, :string},
      {:shipping_option_id, :string, :optional},
      {:order_info, OrderInfo, :optional},
      {:telegram_payment_charge_id, :string},
      {:provider_payment_charge_id, :string}
    ])

    model(ShippingQuery, [
      {:id, :string},
      {:from, User},
      {:invoice_payload, :string},
      {:shipping_address, ShippingAddress}
    ])

    model(PreCheckoutQuery, [
      {:id, :string},
      {:from, User},
      {:currency, :string},
      {:total_amount, :integer},
      {:invoice_payload, :string},
      {:shipping_option_id, :string, :optional},
      {:order_info, OrderInfo, :optional}
    ])

    model(PassportData, [
      {:data, {:array, EncryptedPassportElement}},
      {:credentials, EncryptedCredentials}
    ])

    model(PassportFile, [
      {:file_id, :string},
      {:file_unique_id, :string},
      {:file_size, :integer},
      {:file_date, :integer}
    ])

    model(EncryptedPassportElement, [
      {:type, :string},
      {:data, :string, :optional},
      {:phone_number, :string, :optional},
      {:email, :string, :optional},
      {:files, {:array, PassportFile}, :optional},
      {:front_side, PassportFile, :optional},
      {:reverse_side, PassportFile, :optional},
      {:selfie, PassportFile, :optional},
      {:translation, {:array, PassportFile}, :optional},
      {:hash, :string}
    ])

    model(EncryptedCredentials, [{:data, :string}, {:hash, :string}, {:secret, :string}])

    model(PassportElementErrorDataField, [
      {:source, :string},
      {:type, :string},
      {:field_name, :string},
      {:data_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorFrontSide, [
      {:source, :string},
      {:type, :string},
      {:file_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorReverseSide, [
      {:source, :string},
      {:type, :string},
      {:file_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorSelfie, [
      {:source, :string},
      {:type, :string},
      {:file_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorFile, [
      {:source, :string},
      {:type, :string},
      {:file_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorFiles, [
      {:source, :string},
      {:type, :string},
      {:file_hashes, {:array, :string}},
      {:message, :string}
    ])

    model(PassportElementErrorTranslationFile, [
      {:source, :string},
      {:type, :string},
      {:file_hash, :string},
      {:message, :string}
    ])

    model(PassportElementErrorTranslationFiles, [
      {:source, :string},
      {:type, :string},
      {:file_hashes, {:array, :string}},
      {:message, :string}
    ])

    model(PassportElementErrorUnspecified, [
      {:source, :string},
      {:type, :string},
      {:element_hash, :string},
      {:message, :string}
    ])

    model(Game, [
      {:title, :string},
      {:description, :string},
      {:photo, {:array, PhotoSize}},
      {:text, :string, :optional},
      {:text_entities, {:array, MessageEntity}, :optional},
      {:animation, Animation, :optional}
    ])

    model(CallbackGame, [
      {:user_id, :integer},
      {:score, :integer},
      {:force, :boolean, :optional},
      {:disable_edit_message, :boolean, :optional},
      {:chat_id, :integer, :optional},
      {:message_id, :integer, :optional},
      {:inline_message_id, :string, :optional}
    ])

    model(GameHighScore, [{:position, :integer}, {:user, User}, {:score, :integer}])

    # 119 models

    defmodule ChatMember do
      @moduledoc """
      ChatMember model. Valid subtypes: ChatMemberOwner, ChatMemberAdministrator, ChatMemberMember, ChatMemberRestricted, ChatMemberLeft, ChatMemberBanned
      """
      @type t ::
              ChatMemberOwner.t()
              | ChatMemberAdministrator.t()
              | ChatMemberMember.t()
              | ChatMemberRestricted.t()
              | ChatMemberLeft.t()
              | ChatMemberBanned.t()

      def decode_as, do: %{}

      def subtypes do
        [
          ChatMemberOwner,
          ChatMemberAdministrator,
          ChatMemberMember,
          ChatMemberRestricted,
          ChatMemberLeft,
          ChatMemberBanned
        ]
      end
    end

    defmodule BotCommandScope do
      @moduledoc """
      BotCommandScope model. Valid subtypes: BotCommandScopeDefault, BotCommandScopeAllPrivateChats, BotCommandScopeAllGroupChats, BotCommandScopeAllChatAdministrators, BotCommandScopeChat, BotCommandScopeChatAdministrators, BotCommandScopeChatMember
      """
      @type t ::
              BotCommandScopeDefault.t()
              | BotCommandScopeAllPrivateChats.t()
              | BotCommandScopeAllGroupChats.t()
              | BotCommandScopeAllChatAdministrators.t()
              | BotCommandScopeChat.t()
              | BotCommandScopeChatAdministrators.t()
              | BotCommandScopeChatMember.t()

      def decode_as, do: %{}

      def subtypes do
        [
          BotCommandScopeDefault,
          BotCommandScopeAllPrivateChats,
          BotCommandScopeAllGroupChats,
          BotCommandScopeAllChatAdministrators,
          BotCommandScopeChat,
          BotCommandScopeChatAdministrators,
          BotCommandScopeChatMember
        ]
      end
    end

    defmodule InlineQueryResult do
      @moduledoc """
      InlineQueryResult model. Valid subtypes: InlineQueryResultCachedAudio, InlineQueryResultCachedDocument, InlineQueryResultCachedGif, InlineQueryResultCachedMpeg4Gif, InlineQueryResultCachedPhoto, InlineQueryResultCachedSticker, InlineQueryResultCachedVideo, InlineQueryResultCachedVoice, InlineQueryResultArticle, InlineQueryResultAudio, InlineQueryResultContact, InlineQueryResultGame, InlineQueryResultDocument, InlineQueryResultGif, InlineQueryResultLocation, InlineQueryResultMpeg4Gif, InlineQueryResultPhoto, InlineQueryResultVenue, InlineQueryResultVideo, InlineQueryResultVoice
      """
      @type t ::
              InlineQueryResultCachedAudio.t()
              | InlineQueryResultCachedDocument.t()
              | InlineQueryResultCachedGif.t()
              | InlineQueryResultCachedMpeg4Gif.t()
              | InlineQueryResultCachedPhoto.t()
              | InlineQueryResultCachedSticker.t()
              | InlineQueryResultCachedVideo.t()
              | InlineQueryResultCachedVoice.t()
              | InlineQueryResultArticle.t()
              | InlineQueryResultAudio.t()
              | InlineQueryResultContact.t()
              | InlineQueryResultGame.t()
              | InlineQueryResultDocument.t()
              | InlineQueryResultGif.t()
              | InlineQueryResultLocation.t()
              | InlineQueryResultMpeg4Gif.t()
              | InlineQueryResultPhoto.t()
              | InlineQueryResultVenue.t()
              | InlineQueryResultVideo.t()
              | InlineQueryResultVoice.t()

      def decode_as, do: %{}

      def subtypes do
        [
          InlineQueryResultCachedAudio,
          InlineQueryResultCachedDocument,
          InlineQueryResultCachedGif,
          InlineQueryResultCachedMpeg4Gif,
          InlineQueryResultCachedPhoto,
          InlineQueryResultCachedSticker,
          InlineQueryResultCachedVideo,
          InlineQueryResultCachedVoice,
          InlineQueryResultArticle,
          InlineQueryResultAudio,
          InlineQueryResultContact,
          InlineQueryResultGame,
          InlineQueryResultDocument,
          InlineQueryResultGif,
          InlineQueryResultLocation,
          InlineQueryResultMpeg4Gif,
          InlineQueryResultPhoto,
          InlineQueryResultVenue,
          InlineQueryResultVideo,
          InlineQueryResultVoice
        ]
      end
    end

    defmodule InputMessageContent do
      @moduledoc """
      InputMessageContent model. Valid subtypes: InputTextMessageContent, InputLocationMessageContent, InputVenueMessageContent, InputContactMessageContent, InputInvoiceMessageContent
      """
      @type t ::
              InputTextMessageContent.t()
              | InputLocationMessageContent.t()
              | InputVenueMessageContent.t()
              | InputContactMessageContent.t()
              | InputInvoiceMessageContent.t()

      def decode_as, do: %{}

      def subtypes do
        [
          InputTextMessageContent,
          InputLocationMessageContent,
          InputVenueMessageContent,
          InputContactMessageContent,
          InputInvoiceMessageContent
        ]
      end
    end

    defmodule PassportElementError do
      @moduledoc """
      PassportElementError model. Valid subtypes: PassportElementErrorDataField, PassportElementErrorFrontSide, PassportElementErrorReverseSide, PassportElementErrorSelfie, PassportElementErrorFile, PassportElementErrorFiles, PassportElementErrorTranslationFile, PassportElementErrorTranslationFiles, PassportElementErrorUnspecified
      """
      @type t ::
              PassportElementErrorDataField.t()
              | PassportElementErrorFrontSide.t()
              | PassportElementErrorReverseSide.t()
              | PassportElementErrorSelfie.t()
              | PassportElementErrorFile.t()
              | PassportElementErrorFiles.t()
              | PassportElementErrorTranslationFile.t()
              | PassportElementErrorTranslationFiles.t()
              | PassportElementErrorUnspecified.t()

      def decode_as, do: %{}

      def subtypes do
        [
          PassportElementErrorDataField,
          PassportElementErrorFrontSide,
          PassportElementErrorReverseSide,
          PassportElementErrorSelfie,
          PassportElementErrorFile,
          PassportElementErrorFiles,
          PassportElementErrorTranslationFile,
          PassportElementErrorTranslationFiles,
          PassportElementErrorUnspecified
        ]
      end
    end

    # 5 generics
  end
end
