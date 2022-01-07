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

  # START AUTO GENERATED

  # ----------METHODS-----------

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
    [ExGram.Model.Update],
    "Use this method to receive incoming updates using long polling (wiki). An Array of Update objects is returned."
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
    true,
    "Use this method to specify a url and receive incoming updates via an outgoing webhook. Whenever there is an update for the bot, we will send an HTTPS POST request to the specified url, containing a JSON-serialized Update. In case of an unsuccessful request, we will give up after a reasonable amount of attempts. Returns True on success."
  )

  method(
    :post,
    "deleteWebhook",
    [],
    true,
    "Use this method to remove webhook integration if you decide to switch back to getUpdates. Returns True on success."
  )

  method(
    :get,
    "getWebhookInfo",
    [],
    ExGram.Model.WebhookInfo,
    "Use this method to get current webhook status. Requires no parameters. On success, returns a WebhookInfo object. If the bot is using getUpdates, will return an object with the url field empty."
  )

  method(
    :get,
    "getMe",
    [],
    ExGram.Model.User,
    "A simple method for testing your bot's authentication token. Requires no parameters. Returns basic information about the bot in form of a User object."
  )

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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    true,
    "Use this method to log out from the cloud Bot API server before launching the bot locally. You must log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates. After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes. Returns True on success. Requires no parameters."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    true,
    "Use this method to close the bot instance before moving it from one local server to another. You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart. The method will return error 429 in the first 10 minutes after the bot is launched. Returns True on success. Requires no parameters."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send text messages. On success, the sent Message is returned."
  )

  method(
    :post,
    "forwardMessage",
    [
      {chat_id, [:integer, :string]},
      {from_chat_id, [:integer, :string]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {message_id, [:integer]}
    ],
    ExGram.Model.Message,
    "Use this method to forward messages of any kind. Service messages can't be forwarded. On success, the sent Message is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.MessageId,
    "Use this method to copy messages of any kind. Service messages and invoice messages can't be copied. The method is analogous to the method forwardMessage, but the copied message doesn't have a link to the original message. Returns the MessageId of the sent message on success."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send photos. On success, the sent Message is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent Message is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send general files. On success, the sent Message is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as Document). On success, the sent Message is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent Message is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .OGG file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent Message is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "As of v.4.0, Telegram clients support rounded square mp4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendMediaGroup",
    [
      {chat_id, [:integer, :string]},
      {media,
       [{:array, [InputMediaAudio, InputMediaDocument, InputMediaPhoto, InputMediaVideo]}]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional}
    ],
    [ExGram.Model.Message],
    "Use this method to send a group of photos, videos, documents or audios as an album. Documents and audio files can be only grouped in an album with messages of the same type. On success, an array of Messages that were sent is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send point on the map. On success, the sent Message is returned."
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
    ExGram.Model.Message,
    "Use this method to edit live location messages. A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned."
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
    ExGram.Model.Message,
    "Use this method to stop updating a live location message before live_period expires. On success, if the message is not an inline message, the edited Message is returned, otherwise True is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send information about a venue. On success, the sent Message is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send phone contacts. On success, the sent Message is returned."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send a native poll. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendDice",
    [
      {chat_id, [:integer, :string]},
      {emoji, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send an animated emoji that will display a random value. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendChatAction",
    [{chat_id, [:integer, :string]}, {action, [:string]}],
    true,
    "Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success."
  )

  method(
    :get,
    "getUserProfilePhotos",
    [{user_id, [:integer]}, {offset, [:integer], :optional}, {limit, [:integer], :optional}],
    ExGram.Model.UserProfilePhotos,
    "Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object."
  )

  method(
    :get,
    "getFile",
    [{file_id, [:string]}],
    ExGram.Model.File,
    "Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again."
  )

  method(
    :post,
    "banChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {until_date, [:integer], :optional},
      {revoke_messages, [:boolean], :optional}
    ],
    true,
    "Use this method to ban a user in a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the chat on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "unbanChatMember",
    [
      {chat_id, [:integer, :string]},
      {user_id, [:integer]},
      {only_if_banned, [:boolean], :optional}
    ],
    true,
    "Use this method to unban a previously banned user in a supergroup or channel. The user will not return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. By default, this method guarantees that after the call the user is not a member of the chat, but will be able to join it. So if the user is a member of the chat they will also be removed from the chat. If you don't want this, use the parameter only_if_banned. Returns True on success."
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
    true,
    "Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate administrator rights. Pass True for all permissions to lift restrictions from a user. Returns True on success."
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
    true,
    "Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Pass False for all boolean parameters to demote a user. Returns True on success."
  )

  method(
    :post,
    "setChatAdministratorCustomTitle",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}, {custom_title, [:string]}],
    true,
    "Use this method to set a custom title for an administrator in a supergroup promoted by the bot. Returns True on success."
  )

  method(
    :post,
    "banChatSenderChat",
    [{chat_id, [:integer, :string]}, {sender_chat_id, [:integer]}],
    true,
    "Use this method to ban a channel chat in a supergroup or a channel. Until the chat is unbanned, the owner of the banned chat won't be able to send messages on behalf of any of their channels. The bot must be an administrator in the supergroup or channel for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "unbanChatSenderChat",
    [{chat_id, [:integer, :string]}, {sender_chat_id, [:integer]}],
    true,
    "Use this method to unban a previously banned channel chat in a supergroup or channel. The bot must be an administrator for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "setChatPermissions",
    [{chat_id, [:integer, :string]}, {permissions, [ChatPermissions]}],
    true,
    "Use this method to set default chat permissions for all members. The bot must be an administrator in the group or a supergroup for this to work and must have the can_restrict_members administrator rights. Returns True on success."
  )

  method(
    :post,
    "exportChatInviteLink",
    [{chat_id, [:integer, :string]}],
    :string,
    "Use this method to generate a new primary invite link for a chat; any previously generated primary link is revoked. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the new invite link as String on success."
  )

  method(
    :post,
    "createChatInviteLink",
    [
      {chat_id, [:integer, :string]},
      {name, [:string], :optional},
      {expire_date, [:integer], :optional},
      {member_limit, [:integer], :optional},
      {creates_join_request, [:boolean], :optional}
    ],
    ExGram.Model.ChatInviteLink,
    "Use this method to create an additional invite link for a chat. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. The link can be revoked using the method revokeChatInviteLink. Returns the new invite link as ChatInviteLink object."
  )

  method(
    :post,
    "editChatInviteLink",
    [
      {chat_id, [:integer, :string]},
      {invite_link, [:string]},
      {name, [:string], :optional},
      {expire_date, [:integer], :optional},
      {member_limit, [:integer], :optional},
      {creates_join_request, [:boolean], :optional}
    ],
    ExGram.Model.ChatInviteLink,
    "Use this method to edit a non-primary invite link created by the bot. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the edited invite link as a ChatInviteLink object."
  )

  method(
    :post,
    "revokeChatInviteLink",
    [{chat_id, [:integer, :string]}, {invite_link, [:string]}],
    ExGram.Model.ChatInviteLink,
    "Use this method to revoke an invite link created by the bot. If the primary link is revoked, a new link is automatically generated. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the revoked invite link as ChatInviteLink object."
  )

  method(
    :post,
    "approveChatJoinRequest",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}],
    true,
    "Use this method to approve a chat join request. The bot must be an administrator in the chat for this to work and must have the can_invite_users administrator right. Returns True on success."
  )

  method(
    :post,
    "declineChatJoinRequest",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}],
    true,
    "Use this method to decline a chat join request. The bot must be an administrator in the chat for this to work and must have the can_invite_users administrator right. Returns True on success."
  )

  method(
    :post,
    "setChatPhoto",
    [{chat_id, [:integer, :string]}, {photo, [:file]}],
    true,
    "Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "deleteChatPhoto",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "setChatTitle",
    [{chat_id, [:integer, :string]}, {title, [:string]}],
    true,
    "Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "setChatDescription",
    [{chat_id, [:integer, :string]}, {description, [:string], :optional}],
    true,
    "Use this method to change the description of a group, a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success."
  )

  method(
    :post,
    "pinChatMessage",
    [
      {chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {disable_notification, [:boolean], :optional}
    ],
    true,
    "Use this method to add a message to the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns True on success."
  )

  method(
    :post,
    "unpinChatMessage",
    [{chat_id, [:integer, :string]}, {message_id, [:integer], :optional}],
    true,
    "Use this method to remove a message from the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns True on success."
  )

  method(
    :post,
    "unpinAllChatMessages",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to clear the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns True on success."
  )

  method(
    :post,
    "leaveChat",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method for your bot to leave a group, supergroup or channel. Returns True on success."
  )

  method(
    :get,
    "getChat",
    [{chat_id, [:integer, :string]}],
    ExGram.Model.Chat,
    "Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a Chat object on success."
  )

  method(
    :get,
    "getChatAdministrators",
    [{chat_id, [:integer, :string]}],
    [ExGram.Model.ChatMember],
    "Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember objects that contains information about all chat administrators except other bots. If the chat is a group or a supergroup and no administrators were appointed, only the creator will be returned."
  )

  method(
    :get,
    "getChatMemberCount",
    [{chat_id, [:integer, :string]}],
    :integer,
    "Use this method to get the number of members in a chat. Returns Int on success."
  )

  method(
    :get,
    "getChatMember",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}],
    ExGram.Model.ChatMember,
    "Use this method to get information about a member of a chat. Returns a ChatMember object on success."
  )

  method(
    :post,
    "setChatStickerSet",
    [{chat_id, [:integer, :string]}, {sticker_set_name, [:string]}],
    true,
    "Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success."
  )

  method(
    :post,
    "deleteChatStickerSet",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success."
  )

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
    true,
    "Use this method to send answers to callback queries sent from inline keyboards. The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, True is returned."
  )

  method(
    :post,
    "setMyCommands",
    [
      {commands, [{:array, BotCommand}]},
      {scope, [BotCommandScope], :optional},
      {language_code, [:string], :optional}
    ],
    true,
    "Use this method to change the list of the bot's commands. See https://core.telegram.org/bots#commands for more details about bot commands. Returns True on success."
  )

  method(
    :post,
    "deleteMyCommands",
    [{scope, [BotCommandScope], :optional}, {language_code, [:string], :optional}],
    true,
    "Use this method to delete the list of the bot's commands for the given scope and user language. After deletion, higher level commands will be shown to affected users. Returns True on success."
  )

  method(
    :get,
    "getMyCommands",
    [],
    [ExGram.Model.BotCommand],
    "Use this method to get the current list of the bot's commands for the given scope and user language. Returns Array of BotCommand on success. If commands aren't set, an empty list is returned."
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
      {entities, [{:array, MessageEntity}], :optional},
      {disable_web_page_preview, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to edit text and game messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned."
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
    ExGram.Model.Message,
    "Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned."
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
    ExGram.Model.Message,
    "Use this method to edit animation, audio, document, photo, or video messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded; use a previously uploaded file via its file_id or specify a URL. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned."
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
    ExGram.Model.Message,
    "Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned."
  )

  method(
    :post,
    "stopPoll",
    [
      {chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Poll,
    "Use this method to stop a poll which was sent by the bot. On success, the stopped Poll is returned."
  )

  method(
    :post,
    "deleteMessage",
    [{chat_id, [:integer, :string]}, {message_id, [:integer]}],
    true,
    "Use this method to delete a message, including service messages, with the following limitations: - A message can only be deleted if it was sent less than 48 hours ago. - A dice message in a private chat can only be deleted if it was sent more than 24 hours ago. - Bots can delete outgoing messages in private chats, groups, and supergroups. - Bots can delete incoming messages in private chats. - Bots granted can_post_messages permissions can delete outgoing messages in channels. - If the bot is an administrator of a group, it can delete any message there. - If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there. Returns True on success."
  )

  method(
    :post,
    "sendSticker",
    [
      {chat_id, [:integer, :string]},
      {sticker, [:file, :string]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply],
       :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send static .WEBP or animated .TGS stickers. On success, the sent Message is returned."
  )

  method(
    :get,
    "getStickerSet",
    [{name, [:string]}],
    ExGram.Model.StickerSet,
    "Use this method to get a sticker set. On success, a StickerSet object is returned."
  )

  method(
    :post,
    "uploadStickerFile",
    [{user_id, [:integer]}, {png_sticker, [:file]}],
    ExGram.Model.File,
    "Use this method to upload a .PNG file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times). Returns the uploaded File on success."
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
    true,
    "Use this method to create a new sticker set owned by a user. The bot will be able to edit the sticker set thus created. You must use exactly one of the fields png_sticker or tgs_sticker. Returns True on success."
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
    true,
    "Use this method to add a new sticker to a set created by the bot. You must use exactly one of the fields png_sticker or tgs_sticker. Animated stickers can be added to animated sticker sets and only to them. Animated sticker sets can have up to 50 stickers. Static sticker sets can have up to 120 stickers. Returns True on success."
  )

  method(
    :post,
    "setStickerPositionInSet",
    [{sticker, [:string]}, {position, [:integer]}],
    true,
    "Use this method to move a sticker in a set created by the bot to a specific position. Returns True on success."
  )

  method(
    :post,
    "deleteStickerFromSet",
    [{sticker, [:string]}],
    true,
    "Use this method to delete a sticker from a set created by the bot. Returns True on success."
  )

  method(
    :post,
    "setStickerSetThumb",
    [{name, [:string]}, {user_id, [:integer]}, {thumb, [:file, :string], :optional}],
    true,
    "Use this method to set the thumbnail of a sticker set. Animated thumbnails can be set for animated sticker sets only. Returns True on success."
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
    true,
    "Use this method to send answers to an inline query. On success, True is returned. No more than 50 results per query are allowed."
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
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send invoices. On success, the sent Message is returned."
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
    true,
    "If you sent an invoice requesting a shipping address and the parameter is_flexible was specified, the Bot API will send an Update with a shipping_query field to the bot. Use this method to reply to shipping queries. On success, True is returned."
  )

  method(
    :post,
    "answerPreCheckoutQuery",
    [{pre_checkout_query_id, [:string]}, {ok, [:boolean]}, {error_message, [:string], :optional}],
    true,
    "Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an Update with the field pre_checkout_query. Use this method to respond to such pre-checkout queries. On success, True is returned. Note: The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent."
  )

  method(
    :post,
    "setPassportDataErrors",
    [{user_id, [:integer]}, {errors, [{:array, PassportElementError}]}],
    true,
    "Informs a user that some of the Telegram Passport elements they provided contains errors. The user will not be able to re-submit their Passport to you until the errors are fixed (the contents of the field for which you returned the error must change). Returns True on success."
  )

  method(
    :post,
    "sendGame",
    [
      {chat_id, [:integer]},
      {game_short_name, [:string]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_to_message_id, [:integer], :optional},
      {allow_sending_without_reply, [:boolean], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send a game. On success, the sent Message is returned."
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
    ExGram.Model.Message,
    "Use this method to set the score of the specified user in a game message. On success, if the message is not an inline message, the Message is returned, otherwise True is returned. Returns an error, if the new score is not greater than the user's current score in the chat and force is False."
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
    [ExGram.Model.GameHighScore],
    "Use this method to get data for high score tables. Will return the score of the specified user and several of their neighbors in a game. On success, returns an Array of GameHighScore objects."
  )

  # 82 methods

  # ----------MODELS-----------

  # Models

  defmodule Model do
    @moduledoc """
    Telegram API Model structures
    """

    model(
      Update,
      [
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
        {:chat_member, ChatMemberUpdated, :optional},
        {:chat_join_request, ChatJoinRequest, :optional}
      ],
      "This object represents an incoming update. At most one of the optional parameters can be present in any given update."
    )

    model(
      WebhookInfo,
      [
        {:url, :string},
        {:has_custom_certificate, :boolean},
        {:pending_update_count, :integer},
        {:ip_address, :string, :optional},
        {:last_error_date, :integer, :optional},
        {:last_error_message, :string, :optional},
        {:max_connections, :integer, :optional},
        {:allowed_updates, {:array, :string}, :optional}
      ],
      "Contains information about the current status of a webhook."
    )

    model(
      User,
      [
        {:id, :integer},
        {:is_bot, :boolean},
        {:first_name, :string},
        {:last_name, :string, :optional},
        {:username, :string, :optional},
        {:language_code, :string, :optional},
        {:can_join_groups, :boolean, :optional},
        {:can_read_all_group_messages, :boolean, :optional},
        {:supports_inline_queries, :boolean, :optional}
      ],
      "This object represents a Telegram user or bot."
    )

    model(
      Chat,
      [
        {:id, :integer},
        {:type, :string},
        {:title, :string, :optional},
        {:username, :string, :optional},
        {:first_name, :string, :optional},
        {:last_name, :string, :optional},
        {:photo, ChatPhoto, :optional},
        {:bio, :string, :optional},
        {:has_private_forwards, :boolean, :optional},
        {:description, :string, :optional},
        {:invite_link, :string, :optional},
        {:pinned_message, Message, :optional},
        {:permissions, ChatPermissions, :optional},
        {:slow_mode_delay, :integer, :optional},
        {:message_auto_delete_time, :integer, :optional},
        {:has_protected_content, :boolean, :optional},
        {:sticker_set_name, :string, :optional},
        {:can_set_sticker_set, :boolean, :optional},
        {:linked_chat_id, :integer, :optional},
        {:location, ChatLocation, :optional}
      ],
      "This object represents a chat."
    )

    model(
      Message,
      [
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
        {:is_automatic_forward, :boolean, :optional},
        {:reply_to_message, Message, :optional},
        {:via_bot, User, :optional},
        {:edit_date, :integer, :optional},
        {:has_protected_content, :boolean, :optional},
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
      ],
      "This object represents a message."
    )

    model(
      MessageId,
      [{:message_id, :integer}],
      "This object represents a unique message identifier."
    )

    model(
      MessageEntity,
      [
        {:type, :string},
        {:offset, :integer},
        {:length, :integer},
        {:url, :string, :optional},
        {:user, User, :optional},
        {:language, :string, :optional}
      ],
      "This object represents one special entity in a text message. For example, hashtags, usernames, URLs, etc."
    )

    model(
      PhotoSize,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:width, :integer},
        {:height, :integer},
        {:file_size, :integer, :optional}
      ],
      "This object represents one size of a photo or a file / sticker thumbnail."
    )

    model(
      Animation,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:width, :integer},
        {:height, :integer},
        {:duration, :integer},
        {:thumb, PhotoSize, :optional},
        {:file_name, :string, :optional},
        {:mime_type, :string, :optional},
        {:file_size, :integer, :optional}
      ],
      "This object represents an animation file (GIF or H.264/MPEG-4 AVC video without sound)."
    )

    model(
      Audio,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:duration, :integer},
        {:performer, :string, :optional},
        {:title, :string, :optional},
        {:file_name, :string, :optional},
        {:mime_type, :string, :optional},
        {:file_size, :integer, :optional},
        {:thumb, PhotoSize, :optional}
      ],
      "This object represents an audio file to be treated as music by the Telegram clients."
    )

    model(
      Document,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:thumb, PhotoSize, :optional},
        {:file_name, :string, :optional},
        {:mime_type, :string, :optional},
        {:file_size, :integer, :optional}
      ],
      "This object represents a general file (as opposed to photos, voice messages and audio files)."
    )

    model(
      Video,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:width, :integer},
        {:height, :integer},
        {:duration, :integer},
        {:thumb, PhotoSize, :optional},
        {:file_name, :string, :optional},
        {:mime_type, :string, :optional},
        {:file_size, :integer, :optional}
      ],
      "This object represents a video file."
    )

    model(
      VideoNote,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:length, :integer},
        {:duration, :integer},
        {:thumb, PhotoSize, :optional},
        {:file_size, :integer, :optional}
      ],
      "This object represents a video message (available in Telegram apps as of v.4.0)."
    )

    model(
      Voice,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:duration, :integer},
        {:mime_type, :string, :optional},
        {:file_size, :integer, :optional}
      ],
      "This object represents a voice note."
    )

    model(
      Contact,
      [
        {:phone_number, :string},
        {:first_name, :string},
        {:last_name, :string, :optional},
        {:user_id, :integer, :optional},
        {:vcard, :string, :optional}
      ],
      "This object represents a phone contact."
    )

    model(
      Dice,
      [{:emoji, :string}, {:value, :integer}],
      "This object represents an animated emoji that displays a random value."
    )

    model(
      PollOption,
      [{:text, :string}, {:voter_count, :integer}],
      "This object contains information about one answer option in a poll."
    )

    model(
      PollAnswer,
      [{:poll_id, :string}, {:user, User}, {:option_ids, {:array, :integer}}],
      "This object represents an answer of a user in a non-anonymous poll."
    )

    model(
      Poll,
      [
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
      ],
      "This object contains information about a poll."
    )

    model(
      Location,
      [
        {:longitude, :float},
        {:latitude, :float},
        {:horizontal_accuracy, :float, :optional},
        {:live_period, :integer, :optional},
        {:heading, :integer, :optional},
        {:proximity_alert_radius, :integer, :optional}
      ],
      "This object represents a point on the map."
    )

    model(
      Venue,
      [
        {:location, Location},
        {:title, :string},
        {:address, :string},
        {:foursquare_id, :string, :optional},
        {:foursquare_type, :string, :optional},
        {:google_place_id, :string, :optional},
        {:google_place_type, :string, :optional}
      ],
      "This object represents a venue."
    )

    model(
      ProximityAlertTriggered,
      [{:traveler, User}, {:watcher, User}, {:distance, :integer}],
      "This object represents the content of a service message, sent whenever a user in the chat triggers a proximity alert set by another user."
    )

    model(
      MessageAutoDeleteTimerChanged,
      [{:message_auto_delete_time, :integer}],
      "This object represents a service message about a change in auto-delete timer settings."
    )

    model(
      VoiceChatScheduled,
      [{:start_date, :integer}],
      "This object represents a service message about a voice chat scheduled in the chat."
    )

    model(
      VoiceChatStarted,
      [{:duration, :integer}],
      "This object represents a service message about a voice chat started in the chat. Currently holds no information."
    )

    model(
      VoiceChatEnded,
      [{:duration, :integer}],
      "This object represents a service message about a voice chat ended in the chat."
    )

    model(
      VoiceChatParticipantsInvited,
      [{:users, {:array, User}, :optional}],
      "This object represents a service message about new members invited to a voice chat."
    )

    model(
      UserProfilePhotos,
      [{:total_count, :integer}, {:photos, {:array, {:array, PhotoSize}}}],
      "This object represent a user's profile pictures."
    )

    model(
      File,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:file_size, :integer, :optional},
        {:file_path, :string, :optional}
      ],
      "This object represents a file ready to be downloaded. The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile."
    )

    model(
      ReplyKeyboardMarkup,
      [
        {:keyboard, {:array, {:array, KeyboardButton}}},
        {:resize_keyboard, :boolean, :optional},
        {:one_time_keyboard, :boolean, :optional},
        {:input_field_placeholder, :string, :optional},
        {:selective, :boolean, :optional}
      ],
      "This object represents a custom keyboard with reply options (see Introduction to bots for details and examples)."
    )

    model(
      KeyboardButton,
      [
        {:text, :string},
        {:request_contact, :boolean, :optional},
        {:request_location, :boolean, :optional},
        {:request_poll, KeyboardButtonPollType, :optional}
      ],
      "This object represents one button of the reply keyboard. For simple text buttons String can be used instead of this object to specify text of the button. Optional fields request_contact, request_location, and request_poll are mutually exclusive."
    )

    model(
      KeyboardButtonPollType,
      [{:type, :string, :optional}],
      "This object represents type of a poll, which is allowed to be created and sent when the corresponding button is pressed."
    )

    model(
      ReplyKeyboardRemove,
      [{:remove_keyboard, :boolean}, {:selective, :boolean, :optional}],
      "Upon receiving a message with this object, Telegram clients will remove the current custom keyboard and display the default letter-keyboard. By default, custom keyboards are displayed until a new keyboard is sent by a bot. An exception is made for one-time keyboards that are hidden immediately after the user presses a button (see ReplyKeyboardMarkup)."
    )

    model(
      InlineKeyboardMarkup,
      [{:inline_keyboard, {:array, {:array, InlineKeyboardButton}}}],
      "This object represents an inline keyboard that appears right next to the message it belongs to."
    )

    model(
      InlineKeyboardButton,
      [
        {:text, :string},
        {:url, :string, :optional},
        {:login_url, LoginUrl, :optional},
        {:callback_data, :string, :optional},
        {:switch_inline_query, :string, :optional},
        {:switch_inline_query_current_chat, :string, :optional},
        {:callback_game, CallbackGame, :optional},
        {:pay, :boolean, :optional}
      ],
      "This object represents one button of an inline keyboard. You must use exactly one of the optional fields."
    )

    model(
      LoginUrl,
      [
        {:url, :string},
        {:forward_text, :string, :optional},
        {:bot_username, :string, :optional},
        {:request_write_access, :boolean, :optional}
      ],
      "This object represents a parameter of the inline keyboard button used to automatically authorize a user. Serves as a great replacement for the Telegram Login Widget when the user is coming from Telegram. All the user needs to do is tap/click a button and confirm that they want to log in:"
    )

    model(
      CallbackQuery,
      [
        {:id, :string},
        {:from, User},
        {:message, Message, :optional},
        {:inline_message_id, :string, :optional},
        {:chat_instance, :string},
        {:data, :string, :optional},
        {:game_short_name, :string, :optional}
      ],
      "This object represents an incoming callback query from a callback button in an inline keyboard. If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present."
    )

    model(
      ForceReply,
      [
        {:force_reply, :boolean},
        {:input_field_placeholder, :string, :optional},
        {:selective, :boolean, :optional}
      ],
      "Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot's message and tapped 'Reply'). This can be extremely useful if you want to create user-friendly step-by-step interfaces without having to sacrifice privacy mode."
    )

    model(
      ChatPhoto,
      [
        {:small_file_id, :string},
        {:small_file_unique_id, :string},
        {:big_file_id, :string},
        {:big_file_unique_id, :string}
      ],
      "This object represents a chat photo."
    )

    model(
      ChatInviteLink,
      [
        {:invite_link, :string},
        {:creator, User},
        {:creates_join_request, :boolean},
        {:is_primary, :boolean},
        {:is_revoked, :boolean},
        {:name, :string, :optional},
        {:expire_date, :integer, :optional},
        {:member_limit, :integer, :optional},
        {:pending_join_request_count, :integer, :optional}
      ],
      "Represents an invite link for a chat."
    )

    model(
      ChatMemberOwner,
      [
        {:status, :string},
        {:user, User},
        {:is_anonymous, :boolean},
        {:custom_title, :string, :optional}
      ],
      "Represents a chat member that owns the chat and has all administrator privileges."
    )

    model(
      ChatMemberAdministrator,
      [
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
      ],
      "Represents a chat member that has some additional privileges."
    )

    model(
      ChatMemberMember,
      [{:status, :string}, {:user, User}],
      "Represents a chat member that has no additional privileges or restrictions."
    )

    model(
      ChatMemberRestricted,
      [
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
      ],
      "Represents a chat member that is under certain restrictions in the chat. Supergroups only."
    )

    model(
      ChatMemberLeft,
      [{:status, :string}, {:user, User}],
      "Represents a chat member that isn't currently a member of the chat, but may join it themselves."
    )

    model(
      ChatMemberBanned,
      [{:status, :string}, {:user, User}, {:until_date, :integer}],
      "Represents a chat member that was banned in the chat and can't return to the chat or view chat messages."
    )

    model(
      ChatMemberUpdated,
      [
        {:chat, Chat},
        {:from, User},
        {:date, :integer},
        {:old_chat_member, ChatMember},
        {:new_chat_member, ChatMember},
        {:invite_link, ChatInviteLink, :optional}
      ],
      "This object represents changes in the status of a chat member."
    )

    model(
      ChatJoinRequest,
      [
        {:chat, Chat},
        {:from, User},
        {:date, :integer},
        {:bio, :string, :optional},
        {:invite_link, ChatInviteLink, :optional}
      ],
      "Represents a join request sent to a chat."
    )

    model(
      ChatPermissions,
      [
        {:can_send_messages, :boolean, :optional},
        {:can_send_media_messages, :boolean, :optional},
        {:can_send_polls, :boolean, :optional},
        {:can_send_other_messages, :boolean, :optional},
        {:can_add_web_page_previews, :boolean, :optional},
        {:can_change_info, :boolean, :optional},
        {:can_invite_users, :boolean, :optional},
        {:can_pin_messages, :boolean, :optional}
      ],
      "Describes actions that a non-administrator user is allowed to take in a chat."
    )

    model(
      ChatLocation,
      [{:location, Location}, {:address, :string}],
      "Represents a location to which a chat is connected."
    )

    model(
      BotCommand,
      [{:command, :string}, {:description, :string}],
      "This object represents a bot command."
    )

    model(
      BotCommandScopeDefault,
      [{:type, :string}],
      "Represents the default scope of bot commands. Default commands are used if no commands with a narrower scope are specified for the user."
    )

    model(
      BotCommandScopeAllPrivateChats,
      [{:type, :string}],
      "Represents the scope of bot commands, covering all private chats."
    )

    model(
      BotCommandScopeAllGroupChats,
      [{:type, :string}],
      "Represents the scope of bot commands, covering all group and supergroup chats."
    )

    model(
      BotCommandScopeAllChatAdministrators,
      [{:type, :string}],
      "Represents the scope of bot commands, covering all group and supergroup chat administrators."
    )

    model(
      BotCommandScopeChat,
      [{:type, :string}, {:chat_id, :integer}],
      "Represents the scope of bot commands, covering a specific chat."
    )

    model(
      BotCommandScopeChatAdministrators,
      [{:type, :string}, {:chat_id, :integer}],
      "Represents the scope of bot commands, covering all administrators of a specific group or supergroup chat."
    )

    model(
      BotCommandScopeChatMember,
      [{:type, :string}, {:chat_id, :integer}, {:user_id, :integer}],
      "Represents the scope of bot commands, covering a specific member of a group or supergroup chat."
    )

    model(
      ResponseParameters,
      [{:migrate_to_chat_id, :integer, :optional}, {:retry_after, :integer, :optional}],
      "Contains information about why a request was unsuccessful."
    )

    model(
      InputMedia,
      [
        {:type, :string},
        {:media, :string},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional}
      ],
      "This object represents the content of a media message to be sent. It should be one of"
    )

    model(
      InputMediaPhoto,
      [
        {:type, :string},
        {:media, :string},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional}
      ],
      "Represents a photo to be sent."
    )

    model(
      InputMediaVideo,
      [
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
      ],
      "Represents a video to be sent."
    )

    model(
      InputMediaAnimation,
      [
        {:type, :string},
        {:media, :string},
        {:thumb, :file, :optional},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:width, :integer, :optional},
        {:height, :integer, :optional},
        {:duration, :integer, :optional}
      ],
      "Represents an animation file (GIF or H.264/MPEG-4 AVC video without sound) to be sent."
    )

    model(
      InputMediaAudio,
      [
        {:type, :string},
        {:media, :string},
        {:thumb, :file, :optional},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:duration, :integer, :optional},
        {:performer, :string, :optional},
        {:title, :string, :optional}
      ],
      "Represents an audio file to be treated as music to be sent."
    )

    model(
      InputMediaDocument,
      [
        {:type, :string},
        {:media, :string},
        {:thumb, :file, :optional},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:disable_content_type_detection, :boolean, :optional}
      ],
      "Represents a general file to be sent."
    )

    model(
      InputFile,
      [
        {:chat_id, :integer},
        {:text, :string},
        {:parse_mode, :string, :optional},
        {:entities, {:array, MessageEntity}, :optional},
        {:disable_web_page_preview, :boolean, :optional},
        {:disable_notification, :boolean, :optional},
        {:protect_content, :boolean, :optional},
        {:reply_to_message_id, :integer, :optional},
        {:allow_sending_without_reply, :boolean, :optional},
        {:reply_markup, InlineKeyboardMarkup, :optional}
      ],
      "This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser."
    )

    model(
      Sticker,
      [
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
      ],
      "This object represents a sticker."
    )

    model(
      StickerSet,
      [
        {:name, :string},
        {:title, :string},
        {:is_animated, :boolean},
        {:contains_masks, :boolean},
        {:stickers, {:array, Sticker}},
        {:thumb, PhotoSize, :optional}
      ],
      "This object represents a sticker set."
    )

    model(
      MaskPosition,
      [{:point, :string}, {:x_shift, :float}, {:y_shift, :float}, {:scale, :float}],
      "This object describes the position on faces where a mask should be placed by default."
    )

    model(
      InlineQuery,
      [
        {:id, :string},
        {:from, User},
        {:query, :string},
        {:offset, :string},
        {:chat_type, :string, :optional},
        {:location, Location, :optional}
      ],
      "This object represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results."
    )

    model(
      InlineQueryResultArticle,
      [
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
      ],
      "Represents a link to an article or web page."
    )

    model(
      InlineQueryResultPhoto,
      [
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
      ],
      "Represents a link to a photo. By default, this photo will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo."
    )

    model(
      InlineQueryResultGif,
      [
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
      ],
      "Represents a link to an animated GIF file. By default, this animated GIF file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultMpeg4Gif,
      [
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
      ],
      "Represents a link to a video animation (H.264/MPEG-4 AVC video without sound). By default, this animated MPEG-4 file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultVideo,
      [
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
      ],
      "Represents a link to a page containing an embedded video player or a video file. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video."
    )

    model(
      InlineQueryResultAudio,
      [
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
      ],
      "Represents a link to an MP3 audio file. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio."
    )

    model(
      InlineQueryResultVoice,
      [
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
      ],
      "Represents a link to a voice recording in an .OGG container encoded with OPUS. By default, this voice recording will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the the voice message."
    )

    model(
      InlineQueryResultDocument,
      [
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
      ],
      "Represents a link to a file. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file. Currently, only .PDF and .ZIP files can be sent using this method."
    )

    model(
      InlineQueryResultLocation,
      [
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
      ],
      "Represents a location on a map. By default, the location will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the location."
    )

    model(
      InlineQueryResultVenue,
      [
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
      ],
      "Represents a venue. By default, the venue will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the venue."
    )

    model(
      InlineQueryResultContact,
      [
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
      ],
      "Represents a contact with a phone number. By default, this contact will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the contact."
    )

    model(
      InlineQueryResultGame,
      [
        {:type, :string},
        {:id, :string},
        {:game_short_name, :string},
        {:reply_markup, InlineKeyboardMarkup, :optional}
      ],
      "Represents a Game."
    )

    model(
      InlineQueryResultCachedPhoto,
      [
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
      ],
      "Represents a link to a photo stored on the Telegram servers. By default, this photo will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo."
    )

    model(
      InlineQueryResultCachedGif,
      [
        {:type, :string},
        {:id, :string},
        {:gif_file_id, :string},
        {:title, :string, :optional},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:reply_markup, InlineKeyboardMarkup, :optional},
        {:input_message_content, InputMessageContent, :optional}
      ],
      "Represents a link to an animated GIF file stored on the Telegram servers. By default, this animated GIF file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with specified content instead of the animation."
    )

    model(
      InlineQueryResultCachedMpeg4Gif,
      [
        {:type, :string},
        {:id, :string},
        {:mpeg4_file_id, :string},
        {:title, :string, :optional},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:reply_markup, InlineKeyboardMarkup, :optional},
        {:input_message_content, InputMessageContent, :optional}
      ],
      "Represents a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers. By default, this animated MPEG-4 file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultCachedSticker,
      [
        {:type, :string},
        {:id, :string},
        {:sticker_file_id, :string},
        {:reply_markup, InlineKeyboardMarkup, :optional},
        {:input_message_content, InputMessageContent, :optional}
      ],
      "Represents a link to a sticker stored on the Telegram servers. By default, this sticker will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the sticker."
    )

    model(
      InlineQueryResultCachedDocument,
      [
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
      ],
      "Represents a link to a file stored on the Telegram servers. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file."
    )

    model(
      InlineQueryResultCachedVideo,
      [
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
      ],
      "Represents a link to a video file stored on the Telegram servers. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video."
    )

    model(
      InlineQueryResultCachedVoice,
      [
        {:type, :string},
        {:id, :string},
        {:voice_file_id, :string},
        {:title, :string},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:reply_markup, InlineKeyboardMarkup, :optional},
        {:input_message_content, InputMessageContent, :optional}
      ],
      "Represents a link to a voice message stored on the Telegram servers. By default, this voice message will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the voice message."
    )

    model(
      InlineQueryResultCachedAudio,
      [
        {:type, :string},
        {:id, :string},
        {:audio_file_id, :string},
        {:caption, :string, :optional},
        {:parse_mode, :string, :optional},
        {:caption_entities, {:array, MessageEntity}, :optional},
        {:reply_markup, InlineKeyboardMarkup, :optional},
        {:input_message_content, InputMessageContent, :optional}
      ],
      "Represents a link to an MP3 audio file stored on the Telegram servers. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio."
    )

    model(
      InputTextMessageContent,
      [
        {:message_text, :string},
        {:parse_mode, :string, :optional},
        {:entities, {:array, MessageEntity}, :optional},
        {:disable_web_page_preview, :boolean, :optional}
      ],
      "Represents the content of a text message to be sent as the result of an inline query."
    )

    model(
      InputLocationMessageContent,
      [
        {:latitude, :float},
        {:longitude, :float},
        {:horizontal_accuracy, :float, :optional},
        {:live_period, :integer, :optional},
        {:heading, :integer, :optional},
        {:proximity_alert_radius, :integer, :optional}
      ],
      "Represents the content of a location message to be sent as the result of an inline query."
    )

    model(
      InputVenueMessageContent,
      [
        {:latitude, :float},
        {:longitude, :float},
        {:title, :string},
        {:address, :string},
        {:foursquare_id, :string, :optional},
        {:foursquare_type, :string, :optional},
        {:google_place_id, :string, :optional},
        {:google_place_type, :string, :optional}
      ],
      "Represents the content of a venue message to be sent as the result of an inline query."
    )

    model(
      InputContactMessageContent,
      [
        {:phone_number, :string},
        {:first_name, :string},
        {:last_name, :string, :optional},
        {:vcard, :string, :optional}
      ],
      "Represents the content of a contact message to be sent as the result of an inline query."
    )

    model(
      InputInvoiceMessageContent,
      [
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
      ],
      "Represents the content of an invoice message to be sent as the result of an inline query."
    )

    model(
      ChosenInlineResult,
      [
        {:result_id, :string},
        {:from, User},
        {:location, Location, :optional},
        {:inline_message_id, :string, :optional},
        {:query, :string}
      ],
      "Represents a result of an inline query that was chosen by the user and sent to their chat partner."
    )

    model(
      LabeledPrice,
      [{:label, :string}, {:amount, :integer}],
      "This object represents a portion of the price for goods or services."
    )

    model(
      Invoice,
      [
        {:title, :string},
        {:description, :string},
        {:start_parameter, :string},
        {:currency, :string},
        {:total_amount, :integer}
      ],
      "This object contains basic information about an invoice."
    )

    model(
      ShippingAddress,
      [
        {:country_code, :string},
        {:state, :string},
        {:city, :string},
        {:street_line1, :string},
        {:street_line2, :string},
        {:post_code, :string}
      ],
      "This object represents a shipping address."
    )

    model(
      OrderInfo,
      [
        {:name, :string, :optional},
        {:phone_number, :string, :optional},
        {:email, :string, :optional},
        {:shipping_address, ShippingAddress, :optional}
      ],
      "This object represents information about an order."
    )

    model(
      ShippingOption,
      [{:id, :string}, {:title, :string}, {:prices, {:array, LabeledPrice}}],
      "This object represents one shipping option."
    )

    model(
      SuccessfulPayment,
      [
        {:currency, :string},
        {:total_amount, :integer},
        {:invoice_payload, :string},
        {:shipping_option_id, :string, :optional},
        {:order_info, OrderInfo, :optional},
        {:telegram_payment_charge_id, :string},
        {:provider_payment_charge_id, :string}
      ],
      "This object contains basic information about a successful payment."
    )

    model(
      ShippingQuery,
      [
        {:id, :string},
        {:from, User},
        {:invoice_payload, :string},
        {:shipping_address, ShippingAddress}
      ],
      "This object contains information about an incoming shipping query."
    )

    model(
      PreCheckoutQuery,
      [
        {:id, :string},
        {:from, User},
        {:currency, :string},
        {:total_amount, :integer},
        {:invoice_payload, :string},
        {:shipping_option_id, :string, :optional},
        {:order_info, OrderInfo, :optional}
      ],
      "This object contains information about an incoming pre-checkout query."
    )

    model(
      PassportData,
      [{:data, {:array, EncryptedPassportElement}}, {:credentials, EncryptedCredentials}],
      "Contains information about Telegram Passport data shared with the bot by the user."
    )

    model(
      PassportFile,
      [
        {:file_id, :string},
        {:file_unique_id, :string},
        {:file_size, :integer},
        {:file_date, :integer}
      ],
      "This object represents a file uploaded to Telegram Passport. Currently all Telegram Passport files are in JPEG format when decrypted and don't exceed 10MB."
    )

    model(
      EncryptedPassportElement,
      [
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
      ],
      "Contains information about documents or other Telegram Passport elements shared with the bot by the user."
    )

    model(
      EncryptedCredentials,
      [{:data, :string}, {:hash, :string}, {:secret, :string}],
      "Contains data required for decrypting and authenticating EncryptedPassportElement. See the Telegram Passport Documentation for a complete description of the data decryption and authentication processes."
    )

    model(
      PassportElementErrorDataField,
      [
        {:source, :string},
        {:type, :string},
        {:field_name, :string},
        {:data_hash, :string},
        {:message, :string}
      ],
      "Represents an issue in one of the data fields that was provided by the user. The error is considered resolved when the field's value changes."
    )

    model(
      PassportElementErrorFrontSide,
      [{:source, :string}, {:type, :string}, {:file_hash, :string}, {:message, :string}],
      "Represents an issue with the front side of a document. The error is considered resolved when the file with the front side of the document changes."
    )

    model(
      PassportElementErrorReverseSide,
      [{:source, :string}, {:type, :string}, {:file_hash, :string}, {:message, :string}],
      "Represents an issue with the reverse side of a document. The error is considered resolved when the file with reverse side of the document changes."
    )

    model(
      PassportElementErrorSelfie,
      [{:source, :string}, {:type, :string}, {:file_hash, :string}, {:message, :string}],
      "Represents an issue with the selfie with a document. The error is considered resolved when the file with the selfie changes."
    )

    model(
      PassportElementErrorFile,
      [{:source, :string}, {:type, :string}, {:file_hash, :string}, {:message, :string}],
      "Represents an issue with a document scan. The error is considered resolved when the file with the document scan changes."
    )

    model(
      PassportElementErrorFiles,
      [
        {:source, :string},
        {:type, :string},
        {:file_hashes, {:array, :string}},
        {:message, :string}
      ],
      "Represents an issue with a list of scans. The error is considered resolved when the list of files containing the scans changes."
    )

    model(
      PassportElementErrorTranslationFile,
      [{:source, :string}, {:type, :string}, {:file_hash, :string}, {:message, :string}],
      "Represents an issue with one of the files that constitute the translation of a document. The error is considered resolved when the file changes."
    )

    model(
      PassportElementErrorTranslationFiles,
      [
        {:source, :string},
        {:type, :string},
        {:file_hashes, {:array, :string}},
        {:message, :string}
      ],
      "Represents an issue with the translated version of a document. The error is considered resolved when a file with the document translation change."
    )

    model(
      PassportElementErrorUnspecified,
      [{:source, :string}, {:type, :string}, {:element_hash, :string}, {:message, :string}],
      "Represents an issue in an unspecified place. The error is considered resolved when new data is added."
    )

    model(
      Game,
      [
        {:title, :string},
        {:description, :string},
        {:photo, {:array, PhotoSize}},
        {:text, :string, :optional},
        {:text_entities, {:array, MessageEntity}, :optional},
        {:animation, Animation, :optional}
      ],
      "This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers."
    )

    model(
      CallbackGame,
      [
        {:user_id, :integer},
        {:score, :integer},
        {:force, :boolean, :optional},
        {:disable_edit_message, :boolean, :optional},
        {:chat_id, :integer, :optional},
        {:message_id, :integer, :optional},
        {:inline_message_id, :string, :optional}
      ],
      "A placeholder, currently holds no information. Use BotFather to set up your game."
    )

    model(
      GameHighScore,
      [{:position, :integer}, {:user, User}, {:score, :integer}],
      "This object represents one row of the high scores table for a game."
    )

    # 120 models

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

  # END AUTO GENERATED
end
