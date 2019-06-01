defmodule ExGram do
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
      {max_connections, [:integer], :optional},
      {allowed_updates, [{:array, :string}], :optional}
    ],
    true
  )

  method(:post, "deleteWebhook", [], true)

  method(:get, "getWebhookInfo", [], ExGram.Model.WebhookInfo)

  method(:get, "getMe", [], ExGram.Model.User)

  method(
    :post,
    "sendMessage",
    [
      {chat_id, [:integer, :string]},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
    "sendPhoto",
    [
      {chat_id, [:integer, :string]},
      {photo, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {duration, [:integer], :optional},
      {performer, [:string], :optional},
      {title, [:string], :optional},
      {thumb, [:file, :string], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {supports_streaming, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {duration, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {media, [{:array, [InputMediaPhoto, InputMediaVideo]}]},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional}
    ],
    ExGram.Model.Messages
  )

  method(
    :post,
    "sendLocation",
    [
      {chat_id, [:integer, :string]},
      {latitude, [:float]},
      {longitude, [:float]},
      {live_period, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
      {disable_notification, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
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
    "kickChatMember",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}, {until_date, [:integer], :optional}],
    true
  )

  method(:post, "unbanChatMember", [{chat_id, [:integer, :string]}, {user_id, [:integer]}], true)

  method(
    :post,
    "restrictChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {until_date, [:integer], :optional},
      {can_send_messages, [:boolean], :optional},
      {can_send_media_messages, [:boolean], :optional},
      {can_send_other_messages, [:boolean], :optional},
      {can_add_web_page_previews, [:boolean], :optional}
    ],
    true
  )

  method(
    :post,
    "promoteChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {can_change_info, [:boolean], :optional},
      {can_post_messages, [:boolean], :optional},
      {can_edit_messages, [:boolean], :optional},
      {can_delete_messages, [:boolean], :optional},
      {can_invite_users, [:boolean], :optional},
      {can_restrict_members, [:boolean], :optional},
      {can_pin_messages, [:boolean], :optional},
      {can_promote_members, [:boolean], :optional}
    ],
    true
  )

  method(:post, "exportChatInviteLink", [{chat_id, [:integer, :string]}], String.t())

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

  method(:post, "unpinChatMessage", [{chat_id, [:integer, :string]}], true)

  method(:post, "leaveChat", [{chat_id, [:integer, :string]}], true)

  method(:get, "getChat", [{chat_id, [:integer, :string]}], ExGram.Model.Chat)

  method(:get, "getChatAdministrators", [{chat_id, [:integer, :string]}], [
    ExGram.Model.ChatMember
  ])

  method(:get, "getChatMembersCount", [{chat_id, [:integer, :string]}], integer)

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
    "editMessageText",
    [
      {chat_id, [:integer, :string], :optional},
      {message_id, [:integer], :optional},
      {inline_message_id, [:string], :optional},
      {text, [:string]},
      {parse_mode, [:string], :optional},
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
    ExGram.Model.results()
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
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message
  )

  method(:get, "getStickerSet", [{name, [:string]}], ExGram.Model.object())

  method(
    :post,
    "uploadStickerFile",
    [{user_id, [:integer]}, {png_sticker, [:file]}],
    ExGram.Model.the()
  )

  method(
    :post,
    "createNewStickerSet",
    [
      {user_id, [:integer]},
      {name, [:string]},
      {title, [:string]},
      {png_sticker, [:file, :string]},
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
      {png_sticker, [:file, :string]},
      {emojis, [:string]},
      {mask_position, [MaskPosition], :optional}
    ],
    true
  )

  method(:post, "setStickerPositionInSet", [{sticker, [:string]}, {position, [:integer]}], true)

  method(:post, "deleteStickerFromSet", [{sticker, [:string]}], true)

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
      {chat_id, [:integer]},
      {title, [:string]},
      {description, [:string]},
      {payload, [:string]},
      {provider_token, [:string]},
      {start_parameter, [:string]},
      {currency, [:string]},
      {prices, [{:array, LabeledPrice}]},
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

  # 64 methods

  # ----------MODELS-----------

  # Models

  defmodule Model do
    model(Update, [
      {:update_id, :integer},
      {:message, Message},
      {:edited_message, Message},
      {:channel_post, Message},
      {:edited_channel_post, Message},
      {:inline_query, InlineQuery},
      {:chosen_inline_result, ChosenInlineResult},
      {:callback_query, CallbackQuery},
      {:shipping_query, ShippingQuery},
      {:pre_checkout_query, PreCheckoutQuery},
      {:poll, Poll}
    ])

    model(WebhookInfo, [
      {:url, :string},
      {:has_custom_certificate, :boolean},
      {:pending_update_count, :integer},
      {:last_error_date, :integer},
      {:last_error_message, :string},
      {:max_connections, :integer},
      {:allowed_updates, {:array, :string}}
    ])

    model(User, [
      {:id, :integer},
      {:is_bot, :boolean},
      {:first_name, :string},
      {:last_name, :string},
      {:username, :string},
      {:language_code, :string}
    ])

    model(Chat, [
      {:id, :integer},
      {:type, :string},
      {:title, :string},
      {:username, :string},
      {:first_name, :string},
      {:last_name, :string},
      {:all_members_are_administrators, :boolean},
      {:photo, ChatPhoto},
      {:description, :string},
      {:invite_link, :string},
      {:pinned_message, Message},
      {:sticker_set_name, :string},
      {:can_set_sticker_set, :boolean}
    ])

    model(Message, [
      {:message_id, :integer},
      {:from, User},
      {:date, :integer},
      {:chat, Chat},
      {:forward_from, User},
      {:forward_from_chat, Chat},
      {:forward_from_message_id, :integer},
      {:forward_signature, :string},
      {:forward_sender_name, :string},
      {:forward_date, :integer},
      {:reply_to_message, Message},
      {:edit_date, :integer},
      {:media_group_id, :string},
      {:author_signature, :string},
      {:text, :string},
      {:entities, {:array, MessageEntity}},
      {:caption_entities, {:array, MessageEntity}},
      {:audio, Audio},
      {:document, Document},
      {:animation, Animation},
      {:game, Game},
      {:photo, {:array, PhotoSize}},
      {:sticker, Sticker},
      {:video, Video},
      {:voice, Voice},
      {:video_note, VideoNote},
      {:caption, :string},
      {:contact, Contact},
      {:location, Location},
      {:venue, Venue},
      {:poll, Poll},
      {:new_chat_members, {:array, User}},
      {:left_chat_member, User},
      {:new_chat_title, :string},
      {:new_chat_photo, {:array, PhotoSize}},
      {:delete_chat_photo, :boolean},
      {:group_chat_created, :boolean},
      {:supergroup_chat_created, :boolean},
      {:channel_chat_created, :boolean},
      {:migrate_to_chat_id, :integer},
      {:migrate_from_chat_id, :integer},
      {:pinned_message, Message},
      {:invoice, Invoice},
      {:successful_payment, SuccessfulPayment},
      {:connected_website, :string},
      {:passport_data, PassportData},
      {:reply_markup, InlineKeyboardMarkup, :optional}
    ])

    model(MessageEntity, [
      {:type, :string},
      {:offset, :integer},
      {:length, :integer},
      {:url, :string},
      {:user, User}
    ])

    model(PhotoSize, [
      {:file_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:file_size, :integer}
    ])

    model(Audio, [
      {:file_id, :string},
      {:duration, :integer},
      {:performer, :string},
      {:title, :string},
      {:mime_type, :string},
      {:file_size, :integer},
      {:thumb, PhotoSize}
    ])

    model(Document, [
      {:file_id, :string},
      {:thumb, PhotoSize},
      {:file_name, :string},
      {:mime_type, :string},
      {:file_size, :integer}
    ])

    model(Video, [
      {:file_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize},
      {:mime_type, :string},
      {:file_size, :integer}
    ])

    model(Animation, [
      {:file_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize},
      {:file_name, :string},
      {:mime_type, :string},
      {:file_size, :integer}
    ])

    model(Voice, [
      {:file_id, :string},
      {:duration, :integer},
      {:mime_type, :string},
      {:file_size, :integer}
    ])

    model(VideoNote, [
      {:file_id, :string},
      {:length, :integer},
      {:duration, :integer},
      {:thumb, PhotoSize},
      {:file_size, :integer}
    ])

    model(Contact, [
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string},
      {:user_id, :integer},
      {:vcard, :string}
    ])

    model(Location, [{:longitude, :float}, {:latitude, :float}])

    model(Venue, [
      {:location, Location},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string},
      {:foursquare_type, :string}
    ])

    model(PollOption, [{:text, :string}, {:voter_count, :integer}])

    model(Poll, [
      {:id, :string},
      {:question, :string},
      {:options, {:array, PollOption}},
      {:is_closed, :boolean}
    ])

    model(UserProfilePhotos, [{:total_count, :integer}, {:photos, {:array, {:array, PhotoSize}}}])

    model(File, [{:file_id, :string}, {:file_size, :integer}, {:file_path, :string}])

    model(ReplyKeyboardMarkup, [
      {:keyboard, {:array, {:array, KeyboardButton}}},
      {:resize_keyboard, :boolean},
      {:one_time_keyboard, :boolean},
      {:selective, :boolean}
    ])

    model(KeyboardButton, [
      {:text, :string},
      {:request_contact, :boolean},
      {:request_location, :boolean}
    ])

    model(ReplyKeyboardRemove, [{:remove_keyboard, :boolean}, {:selective, :boolean}])

    model(InlineKeyboardMarkup, [{:inline_keyboard, {:array, {:array, InlineKeyboardButton}}}])

    model(InlineKeyboardButton, [
      {:text, :string},
      {:url, :string},
      {:login_url, LoginUrl},
      {:callback_data, :string},
      {:switch_inline_query, :string},
      {:switch_inline_query_current_chat, :string},
      {:callback_game, CallbackGame},
      {:pay, :boolean}
    ])

    model(LoginUrl, [
      {:url, :string},
      {:forward_text, :string},
      {:bot_username, :string},
      {:request_write_access, :boolean}
    ])

    model(CallbackQuery, [
      {:id, :string},
      {:from, User},
      {:message, Message},
      {:inline_message_id, :string},
      {:chat_instance, :string},
      {:data, :string},
      {:game_short_name, :string}
    ])

    model(ForceReply, [{:force_reply, :boolean}, {:selective, :boolean}])

    model(ChatPhoto, [{:small_file_id, :string}, {:big_file_id, :string}])

    model(ChatMember, [
      {:user, User},
      {:status, :string},
      {:until_date, :integer},
      {:can_be_edited, :boolean},
      {:can_change_info, :boolean},
      {:can_post_messages, :boolean},
      {:can_edit_messages, :boolean},
      {:can_delete_messages, :boolean},
      {:can_invite_users, :boolean},
      {:can_restrict_members, :boolean},
      {:can_pin_messages, :boolean},
      {:can_promote_members, :boolean},
      {:is_member, :boolean},
      {:can_send_messages, :boolean},
      {:can_send_media_messages, :boolean},
      {:can_send_other_messages, :boolean},
      {:can_add_web_page_previews, :boolean}
    ])

    model(ResponseParameters, [{:migrate_to_chat_id, :integer}, {:retry_after, :integer}])

    model(InputMedia, [
      {:type, :string},
      {:media, :string},
      {:caption, :string},
      {:parse_mode, :string}
    ])

    model(InputMediaPhoto, [
      {:type, :string},
      {:media, :string},
      {:caption, :string},
      {:parse_mode, :string}
    ])

    model(InputMediaVideo, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file},
      {:caption, :string},
      {:parse_mode, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer},
      {:supports_streaming, :boolean}
    ])

    model(InputMediaAnimation, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file},
      {:caption, :string},
      {:parse_mode, :string},
      {:width, :integer},
      {:height, :integer},
      {:duration, :integer}
    ])

    model(InputMediaAudio, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file},
      {:caption, :string},
      {:parse_mode, :string},
      {:duration, :integer},
      {:performer, :string},
      {:title, :string}
    ])

    model(InputMediaDocument, [
      {:type, :string},
      {:media, :string},
      {:thumb, :file},
      {:caption, :string},
      {:parse_mode, :string}
    ])

    model(InputFile, [
      {:chat_id, :integer},
      {:text, :string},
      {:parse_mode, :string, :optional},
      {:disable_web_page_preview, :boolean, :optional},
      {:disable_notification, :boolean, :optional},
      {:reply_to_message_id, :integer, :optional},
      {:reply_markup, InlineKeyboardMarkup, :optional}
    ])

    model(Sticker, [
      {:file_id, :string},
      {:width, :integer},
      {:height, :integer},
      {:thumb, PhotoSize},
      {:emoji, :string},
      {:set_name, :string},
      {:mask_position, MaskPosition},
      {:file_size, :integer}
    ])

    model(StickerSet, [
      {:name, :string},
      {:title, :string},
      {:contains_masks, :boolean},
      {:stickers, {:array, Sticker}}
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
      {:location, Location},
      {:query, :string},
      {:offset, :string}
    ])

    model(InlineQueryResultArticle, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:input_message_content, InputMessageContent},
      {:reply_markup, InlineKeyboardMarkup},
      {:url, :string},
      {:hide_url, :boolean},
      {:description, :string},
      {:thumb_url, :string},
      {:thumb_width, :integer},
      {:thumb_height, :integer}
    ])

    model(InlineQueryResultPhoto, [
      {:type, :string},
      {:id, :string},
      {:photo_url, :string},
      {:thumb_url, :string},
      {:photo_width, :integer},
      {:photo_height, :integer},
      {:title, :string},
      {:description, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultGif, [
      {:type, :string},
      {:id, :string},
      {:gif_url, :string},
      {:gif_width, :integer},
      {:gif_height, :integer},
      {:gif_duration, :integer},
      {:thumb_url, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultMpeg4Gif, [
      {:type, :string},
      {:id, :string},
      {:mpeg4_url, :string},
      {:mpeg4_width, :integer},
      {:mpeg4_height, :integer},
      {:mpeg4_duration, :integer},
      {:thumb_url, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultVideo, [
      {:type, :string},
      {:id, :string},
      {:video_url, :string},
      {:mime_type, :string},
      {:thumb_url, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:video_width, :integer},
      {:video_height, :integer},
      {:video_duration, :integer},
      {:description, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultAudio, [
      {:type, :string},
      {:id, :string},
      {:audio_url, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:performer, :string},
      {:audio_duration, :integer},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultVoice, [
      {:type, :string},
      {:id, :string},
      {:voice_url, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:voice_duration, :integer},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultDocument, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:document_url, :string},
      {:mime_type, :string},
      {:description, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent},
      {:thumb_url, :string},
      {:thumb_width, :integer},
      {:thumb_height, :integer}
    ])

    model(InlineQueryResultLocation, [
      {:type, :string},
      {:id, :string},
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:live_period, :integer},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent},
      {:thumb_url, :string},
      {:thumb_width, :integer},
      {:thumb_height, :integer}
    ])

    model(InlineQueryResultVenue, [
      {:type, :string},
      {:id, :string},
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string},
      {:foursquare_type, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent},
      {:thumb_url, :string},
      {:thumb_width, :integer},
      {:thumb_height, :integer}
    ])

    model(InlineQueryResultContact, [
      {:type, :string},
      {:id, :string},
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string},
      {:vcard, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent},
      {:thumb_url, :string},
      {:thumb_width, :integer},
      {:thumb_height, :integer}
    ])

    model(InlineQueryResultGame, [
      {:type, :string},
      {:id, :string},
      {:game_short_name, :string},
      {:reply_markup, InlineKeyboardMarkup}
    ])

    model(InlineQueryResultCachedPhoto, [
      {:type, :string},
      {:id, :string},
      {:photo_file_id, :string},
      {:title, :string},
      {:description, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedGif, [
      {:type, :string},
      {:id, :string},
      {:gif_file_id, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedMpeg4Gif, [
      {:type, :string},
      {:id, :string},
      {:mpeg4_file_id, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedSticker, [
      {:type, :string},
      {:id, :string},
      {:sticker_file_id, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedDocument, [
      {:type, :string},
      {:id, :string},
      {:title, :string},
      {:document_file_id, :string},
      {:description, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedVideo, [
      {:type, :string},
      {:id, :string},
      {:video_file_id, :string},
      {:title, :string},
      {:description, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedVoice, [
      {:type, :string},
      {:id, :string},
      {:voice_file_id, :string},
      {:title, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InlineQueryResultCachedAudio, [
      {:type, :string},
      {:id, :string},
      {:audio_file_id, :string},
      {:caption, :string},
      {:parse_mode, :string},
      {:reply_markup, InlineKeyboardMarkup},
      {:input_message_content, InputMessageContent}
    ])

    model(InputTextMessageContent, [
      {:message_text, :string},
      {:parse_mode, :string},
      {:disable_web_page_preview, :boolean}
    ])

    model(InputLocationMessageContent, [
      {:latitude, :float},
      {:longitude, :float},
      {:live_period, :integer}
    ])

    model(InputVenueMessageContent, [
      {:latitude, :float},
      {:longitude, :float},
      {:title, :string},
      {:address, :string},
      {:foursquare_id, :string},
      {:foursquare_type, :string}
    ])

    model(InputContactMessageContent, [
      {:phone_number, :string},
      {:first_name, :string},
      {:last_name, :string},
      {:vcard, :string}
    ])

    model(ChosenInlineResult, [
      {:result_id, :string},
      {:from, User},
      {:location, Location},
      {:inline_message_id, :string},
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
      {:name, :string},
      {:phone_number, :string},
      {:email, :string},
      {:shipping_address, ShippingAddress}
    ])

    model(ShippingOption, [{:id, :string}, {:title, :string}, {:prices, {:array, LabeledPrice}}])

    model(SuccessfulPayment, [
      {:currency, :string},
      {:total_amount, :integer},
      {:invoice_payload, :string},
      {:shipping_option_id, :string},
      {:order_info, OrderInfo},
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
      {:shipping_option_id, :string},
      {:order_info, OrderInfo}
    ])

    model(PassportData, [
      {:data, {:array, EncryptedPassportElement}},
      {:credentials, EncryptedCredentials}
    ])

    model(PassportFile, [{:file_id, :string}, {:file_size, :integer}, {:file_date, :integer}])

    model(EncryptedPassportElement, [
      {:type, :string},
      {:data, :string},
      {:phone_number, :string},
      {:email, :string},
      {:files, {:array, PassportFile}},
      {:front_side, PassportFile},
      {:reverse_side, PassportFile},
      {:selfie, PassportFile},
      {:translation, {:array, PassportFile}},
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
      {:text, :string},
      {:text_entities, {:array, MessageEntity}},
      {:animation, Animation}
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

    # 91 models

    defmodule InlineQueryResult do
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

      def subtypes() do
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
      @type t ::
              InputTextMessageContent.t()
              | InputLocationMessageContent.t()
              | InputVenueMessageContent.t()
              | InputContactMessageContent.t()

      def subtypes() do
        [
          InputTextMessageContent,
          InputLocationMessageContent,
          InputVenueMessageContent,
          InputContactMessageContent
        ]
      end
    end

    defmodule PassportElementError do
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

      def subtypes() do
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

    # 3 generics
  end
end
