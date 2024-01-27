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

  defp reload_engine do
    engine = Application.get_env(:ex_gram, :json_engine)
    ExGram.Encoder.EngineCompiler.compile(engine)
  end

  def test_environment? do
    ExGram.Config.get(:ex_gram, :test_environment, false)
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
    {:array, ExGram.Model.Update},
    "Use this method to receive incoming updates using long polling (wiki). Returns an Array of Update objects."
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
      {drop_pending_updates, [:boolean], :optional},
      {secret_token, [:string], :optional}
    ],
    true,
    "Use this method to specify a URL and receive incoming updates via an outgoing webhook. Whenever there is an update for the bot, we will send an HTTPS POST request to the specified URL, containing a JSON-serialized Update. In case of an unsuccessful request, we will give up after a reasonable amount of attempts. Returns True on success."
  )

  method(
    :post,
    "deleteWebhook",
    [{drop_pending_updates, [:boolean], :optional}],
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
    [],
    true,
    "Use this method to log out from the cloud Bot API server before launching the bot locally. You must log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates. After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes. Returns True on success. Requires no parameters."
  )

  method(
    :post,
    "close",
    [],
    true,
    "Use this method to close the bot instance before moving it from one local server to another. You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart. The method will return error 429 in the first 10 minutes after the bot is launched. Returns True on success. Requires no parameters."
  )

  method(
    :post,
    "sendMessage",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {text, [:string]},
      {parse_mode, [:string], :optional},
      {entities, [{:array, MessageEntity}], :optional},
      {link_preview_options, [LinkPreviewOptions], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send text messages. On success, the sent Message is returned."
  )

  method(
    :post,
    "forwardMessage",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {from_chat_id, [:integer, :string]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {message_id, [:integer]}
    ],
    ExGram.Model.Message,
    "Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded. On success, the sent Message is returned."
  )

  method(
    :post,
    "forwardMessages",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {from_chat_id, [:integer, :string]},
      {message_ids, [{:array, :integer}]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional}
    ],
    :any,
    "Use this method to forward multiple messages of any kind. If some of the specified messages can't be found or forwarded, they are skipped. Service messages and messages with protected content can't be forwarded. Album grouping is kept for forwarded messages. On success, an array of MessageId of the sent messages is returned."
  )

  method(
    :post,
    "copyMessage",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {from_chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.MessageId,
    "Use this method to copy messages of any kind. Service messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz poll can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method forwardMessage, but the copied message doesn't have a link to the original message. Returns the MessageId of the sent message on success."
  )

  method(
    :post,
    "copyMessages",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {from_chat_id, [:integer, :string]},
      {message_ids, [{:array, :integer}]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {remove_caption, [:boolean], :optional}
    ],
    :any,
    "Use this method to copy messages of any kind. If some of the specified messages can't be found or copied, they are skipped. Service messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz poll can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method forwardMessages, but the copied messages don't have a link to the original message. Album grouping is kept for copied messages. On success, an array of MessageId of the sent messages is returned."
  )

  method(
    :post,
    "sendPhoto",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {photo, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {has_spoiler, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send photos. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendAudio",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {audio, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {duration, [:integer], :optional},
      {performer, [:string], :optional},
      {title, [:string], :optional},
      {thumbnail, [:file, :string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent Message is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future."
  )

  method(
    :post,
    "sendDocument",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {document, [:file, :string]},
      {thumbnail, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {disable_content_type_detection, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send general files. On success, the sent Message is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future."
  )

  method(
    :post,
    "sendVideo",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {video, [:file, :string]},
      {duration, [:integer], :optional},
      {width, [:integer], :optional},
      {height, [:integer], :optional},
      {thumbnail, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {has_spoiler, [:boolean], :optional},
      {supports_streaming, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send video files, Telegram clients support MPEG4 videos (other formats may be sent as Document). On success, the sent Message is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future."
  )

  method(
    :post,
    "sendAnimation",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {animation, [:file, :string]},
      {duration, [:integer], :optional},
      {width, [:integer], :optional},
      {height, [:integer], :optional},
      {thumbnail, [:file, :string], :optional},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {has_spoiler, [:boolean], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent Message is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future."
  )

  method(
    :post,
    "sendVoice",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {voice, [:file, :string]},
      {caption, [:string], :optional},
      {parse_mode, [:string], :optional},
      {caption_entities, [{:array, MessageEntity}], :optional},
      {duration, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .OGG file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent Message is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future."
  )

  method(
    :post,
    "sendVideoNote",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {video_note, [:file, :string]},
      {duration, [:integer], :optional},
      {length, [:integer], :optional},
      {thumbnail, [:file, :string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "As of v.4.0, Telegram clients support rounded square MPEG4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendMediaGroup",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {media, [{:array, [InputMediaAudio, InputMediaDocument, InputMediaPhoto, InputMediaVideo]}]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional}
    ],
    {:array, ExGram.Model.Message},
    "Use this method to send a group of photos, videos, documents or audios as an album. Documents and audio files can be only grouped in an album with messages of the same type. On success, an array of Messages that were sent is returned."
  )

  method(
    :post,
    "sendLocation",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {latitude, [:float]},
      {longitude, [:float]},
      {horizontal_accuracy, [:float], :optional},
      {live_period, [:integer], :optional},
      {heading, [:integer], :optional},
      {proximity_alert_radius, [:integer], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send point on the map. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendVenue",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
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
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send information about a venue. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendContact",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {phone_number, [:string]},
      {first_name, [:string]},
      {last_name, [:string], :optional},
      {vcard, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send phone contacts. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendPoll",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
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
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send a native poll. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendDice",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {emoji, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send an animated emoji that will display a random value. On success, the sent Message is returned."
  )

  method(
    :post,
    "sendChatAction",
    [{chat_id, [:integer, :string]}, {message_thread_id, [:integer], :optional}, {action, [:string]}],
    true,
    "Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success."
  )

  method(
    :post,
    "setMessageReaction",
    [
      {chat_id, [:integer, :string]},
      {message_id, [:integer]},
      {reaction, [{:array, ReactionType}], :optional},
      {is_big, [:boolean], :optional}
    ],
    true,
    "Use this method to change the chosen reactions on a message. Service messages can't be reacted to. Automatically forwarded messages from a channel to its discussion group have the same available reactions as messages in the channel. In albums, bots must react to the first message. Returns True on success."
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
    "Use this method to get basic information about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again."
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
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}, {only_if_banned, [:boolean], :optional}],
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
      {use_independent_chat_permissions, [:boolean], :optional},
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
      {can_delete_messages, [:boolean], :optional},
      {can_manage_video_chats, [:boolean], :optional},
      {can_restrict_members, [:boolean], :optional},
      {can_promote_members, [:boolean], :optional},
      {can_change_info, [:boolean], :optional},
      {can_invite_users, [:boolean], :optional},
      {can_post_messages, [:boolean], :optional},
      {can_edit_messages, [:boolean], :optional},
      {can_pin_messages, [:boolean], :optional},
      {can_post_stories, [:boolean], :optional},
      {can_edit_stories, [:boolean], :optional},
      {can_delete_stories, [:boolean], :optional},
      {can_manage_topics, [:boolean], :optional}
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
    [
      {chat_id, [:integer, :string]},
      {permissions, [ChatPermissions]},
      {use_independent_chat_permissions, [:boolean], :optional}
    ],
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
    [{chat_id, [:integer, :string]}, {message_id, [:integer]}, {disable_notification, [:boolean], :optional}],
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
    "Use this method to get up to date information about the chat. Returns a Chat object on success."
  )

  method(
    :get,
    "getChatAdministrators",
    [{chat_id, [:integer, :string]}],
    {:array, ExGram.Model.ChatMember},
    "Use this method to get a list of administrators in a chat, which aren't bots. Returns an Array of ChatMember objects."
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
    "Use this method to get information about a member of a chat. The method is only guaranteed to work for other users if the bot is an administrator in the chat. Returns a ChatMember object on success."
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
    :get,
    "getForumTopicIconStickers",
    [
      {chat_id, [:integer, :string]},
      {name, [:string]},
      {icon_color, [:integer], :optional},
      {icon_custom_emoji_id, [:string], :optional}
    ],
    {:array, ExGram.Model.Sticker},
    "Use this method to get custom emoji stickers, which can be used as a forum topic icon by any user. Requires no parameters. Returns an Array of Sticker objects."
  )

  method(
    :post,
    "createForumTopic",
    [
      {chat_id, [:integer, :string]},
      {name, [:string]},
      {icon_color, [:integer], :optional},
      {icon_custom_emoji_id, [:string], :optional}
    ],
    ExGram.Model.ForumTopic,
    "Use this method to create a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights. Returns information about the created topic as a ForumTopic object."
  )

  method(
    :post,
    "editForumTopic",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer]},
      {name, [:string], :optional},
      {icon_custom_emoji_id, [:string], :optional}
    ],
    true,
    "Use this method to edit name and icon of a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have can_manage_topics administrator rights, unless it is the creator of the topic. Returns True on success."
  )

  method(
    :post,
    "closeForumTopic",
    [{chat_id, [:integer, :string]}, {message_thread_id, [:integer]}],
    true,
    "Use this method to close an open topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights, unless it is the creator of the topic. Returns True on success."
  )

  method(
    :post,
    "reopenForumTopic",
    [{chat_id, [:integer, :string]}, {message_thread_id, [:integer]}],
    true,
    "Use this method to reopen a closed topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights, unless it is the creator of the topic. Returns True on success."
  )

  method(
    :post,
    "deleteForumTopic",
    [{chat_id, [:integer, :string]}, {message_thread_id, [:integer]}],
    true,
    "Use this method to delete a forum topic along with all its messages in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_delete_messages administrator rights. Returns True on success."
  )

  method(
    :post,
    "unpinAllForumTopicMessages",
    [{chat_id, [:integer, :string]}, {message_thread_id, [:integer]}],
    true,
    "Use this method to clear the list of pinned messages in a forum topic. The bot must be an administrator in the chat for this to work and must have the can_pin_messages administrator right in the supergroup. Returns True on success."
  )

  method(
    :post,
    "editGeneralForumTopic",
    [{chat_id, [:integer, :string]}, {name, [:string]}],
    true,
    "Use this method to edit the name of the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have can_manage_topics administrator rights. Returns True on success."
  )

  method(
    :post,
    "closeGeneralForumTopic",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to close an open 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights. Returns True on success."
  )

  method(
    :post,
    "reopenGeneralForumTopic",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to reopen a closed 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights. The topic will be automatically unhidden if it was hidden. Returns True on success."
  )

  method(
    :post,
    "hideGeneralForumTopic",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to hide the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights. The topic will be automatically closed if it was open. Returns True on success."
  )

  method(
    :post,
    "unhideGeneralForumTopic",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to unhide the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the can_manage_topics administrator rights. Returns True on success."
  )

  method(
    :post,
    "unpinAllGeneralForumTopicMessages",
    [{chat_id, [:integer, :string]}],
    true,
    "Use this method to clear the list of pinned messages in a General forum topic. The bot must be an administrator in the chat for this to work and must have the can_pin_messages administrator right in the supergroup. Returns True on success."
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
    :get,
    "getUserChatBoosts",
    [{chat_id, [:integer, :string]}, {user_id, [:integer]}],
    ExGram.Model.UserChatBoosts,
    "Use this method to get the list of boosts added to a chat by a user. Requires administrator rights in the chat. Returns a UserChatBoosts object."
  )

  method(
    :post,
    "setMyCommands",
    [{commands, [{:array, BotCommand}]}, {scope, [BotCommandScope], :optional}, {language_code, [:string], :optional}],
    true,
    "Use this method to change the list of the bot's commands. See this manual for more details about bot commands. Returns True on success."
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
    [{scope, [BotCommandScope], :optional}, {language_code, [:string], :optional}],
    {:array, ExGram.Model.BotCommand},
    "Use this method to get the current list of the bot's commands for the given scope and user language. Returns an Array of BotCommand objects. If commands aren't set, an empty list is returned."
  )

  method(
    :post,
    "setMyName",
    [{name, [:string], :optional}, {language_code, [:string], :optional}],
    true,
    "Use this method to change the bot's name. Returns True on success."
  )

  method(
    :get,
    "getMyName",
    [{language_code, [:string], :optional}],
    ExGram.Model.BotName,
    "Use this method to get the current bot name for the given user language. Returns BotName on success."
  )

  method(
    :post,
    "setMyDescription",
    [{description, [:string], :optional}, {language_code, [:string], :optional}],
    true,
    "Use this method to change the bot's description, which is shown in the chat with the bot if the chat is empty. Returns True on success."
  )

  method(
    :get,
    "getMyDescription",
    [{language_code, [:string], :optional}],
    ExGram.Model.BotDescription,
    "Use this method to get the current bot description for the given user language. Returns BotDescription on success."
  )

  method(
    :post,
    "setMyShortDescription",
    [{short_description, [:string], :optional}, {language_code, [:string], :optional}],
    true,
    "Use this method to change the bot's short description, which is shown on the bot's profile page and is sent together with the link when users share the bot. Returns True on success."
  )

  method(
    :get,
    "getMyShortDescription",
    [{language_code, [:string], :optional}],
    ExGram.Model.BotShortDescription,
    "Use this method to get the current bot short description for the given user language. Returns BotShortDescription on success."
  )

  method(
    :post,
    "setChatMenuButton",
    [{chat_id, [:integer], :optional}, {menu_button, [MenuButton], :optional}],
    true,
    "Use this method to change the bot's menu button in a private chat, or the default menu button. Returns True on success."
  )

  method(
    :get,
    "getChatMenuButton",
    [{chat_id, [:integer], :optional}],
    ExGram.Model.MenuButton,
    "Use this method to get the current value of the bot's menu button in a private chat, or the default menu button. Returns MenuButton on success."
  )

  method(
    :post,
    "setMyDefaultAdministratorRights",
    [{rights, [ChatAdministratorRights], :optional}, {for_channels, [:boolean], :optional}],
    true,
    "Use this method to change the default administrator rights requested by the bot when it's added as an administrator to groups or channels. These rights will be suggested to users, but they are free to modify the list before adding the bot. Returns True on success."
  )

  method(
    :get,
    "getMyDefaultAdministratorRights",
    [{for_channels, [:boolean], :optional}],
    ExGram.Model.ChatAdministratorRights,
    "Use this method to get the current default administrator rights of the bot. Returns ChatAdministratorRights on success."
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
      {link_preview_options, [LinkPreviewOptions], :optional},
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
    [{chat_id, [:integer, :string]}, {message_id, [:integer]}, {reply_markup, [InlineKeyboardMarkup], :optional}],
    ExGram.Model.Poll,
    "Use this method to stop a poll which was sent by the bot. On success, the stopped Poll is returned."
  )

  method(
    :post,
    "deleteMessage",
    [{chat_id, [:integer, :string]}, {message_id, [:integer]}],
    true,
    "Use this method to delete a message, including service messages, with the following limitations: - A message can only be deleted if it was sent less than 48 hours ago. - Service messages about a supergroup, channel, or forum topic creation can't be deleted. - A dice message in a private chat can only be deleted if it was sent more than 24 hours ago. - Bots can delete outgoing messages in private chats, groups, and supergroups. - Bots can delete incoming messages in private chats. - Bots granted can_post_messages permissions can delete outgoing messages in channels. - If the bot is an administrator of a group, it can delete any message there. - If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there. Returns True on success."
  )

  method(
    :post,
    "deleteMessages",
    [{chat_id, [:integer, :string]}, {message_ids, [{:array, :integer}]}],
    true,
    "Use this method to delete multiple messages simultaneously. If some of the specified messages can't be found, they are skipped. Returns True on success."
  )

  method(
    :post,
    "sendSticker",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
      {sticker, [:file, :string]},
      {emoji, [:string], :optional},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send static .WEBP, animated .TGS, or video .WEBM stickers. On success, the sent Message is returned."
  )

  method(
    :get,
    "getStickerSet",
    [{name, [:string]}],
    ExGram.Model.StickerSet,
    "Use this method to get a sticker set. On success, a StickerSet object is returned."
  )

  method(
    :get,
    "getCustomEmojiStickers",
    [{custom_emoji_ids, [{:array, :string}]}],
    {:array, ExGram.Model.Sticker},
    "Use this method to get information about custom emoji stickers by their identifiers. Returns an Array of Sticker objects."
  )

  method(
    :post,
    "uploadStickerFile",
    [{user_id, [:integer]}, {sticker, [:file]}, {sticker_format, [:string]}],
    ExGram.Model.File,
    "Use this method to upload a file with a sticker for later use in the createNewStickerSet and addStickerToSet methods (the file can be used multiple times). Returns the uploaded File on success."
  )

  method(
    :post,
    "createNewStickerSet",
    [
      {user_id, [:integer]},
      {name, [:string]},
      {title, [:string]},
      {stickers, [{:array, InputSticker}]},
      {sticker_format, [:string]},
      {sticker_type, [:string], :optional},
      {needs_repainting, [:boolean], :optional}
    ],
    true,
    "Use this method to create a new sticker set owned by a user. The bot will be able to edit the sticker set thus created. Returns True on success."
  )

  method(
    :post,
    "addStickerToSet",
    [{user_id, [:integer]}, {name, [:string]}, {sticker, [InputSticker]}],
    true,
    "Use this method to add a new sticker to a set created by the bot. The format of the added sticker must match the format of the other stickers in the set. Emoji sticker sets can have up to 200 stickers. Animated and video sticker sets can have up to 50 stickers. Static sticker sets can have up to 120 stickers. Returns True on success."
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
    "setStickerEmojiList",
    [{sticker, [:string]}, {emoji_list, [{:array, :string}]}],
    true,
    "Use this method to change the list of emoji assigned to a regular or custom emoji sticker. The sticker must belong to a sticker set created by the bot. Returns True on success."
  )

  method(
    :post,
    "setStickerKeywords",
    [{sticker, [:string]}, {keywords, [{:array, :string}], :optional}],
    true,
    "Use this method to change search keywords assigned to a regular or custom emoji sticker. The sticker must belong to a sticker set created by the bot. Returns True on success."
  )

  method(
    :post,
    "setStickerMaskPosition",
    [{sticker, [:string]}, {mask_position, [MaskPosition], :optional}],
    true,
    "Use this method to change the mask position of a mask sticker. The sticker must belong to a sticker set that was created by the bot. Returns True on success."
  )

  method(
    :post,
    "setStickerSetTitle",
    [{name, [:string]}, {title, [:string]}],
    true,
    "Use this method to set the title of a created sticker set. Returns True on success."
  )

  method(
    :post,
    "setStickerSetThumbnail",
    [{name, [:string]}, {user_id, [:integer]}, {thumbnail, [:file, :string], :optional}],
    true,
    "Use this method to set the thumbnail of a regular or mask sticker set. The format of the thumbnail file must match the format of the stickers in the set. Returns True on success."
  )

  method(
    :post,
    "setCustomEmojiStickerSetThumbnail",
    [{name, [:string]}, {custom_emoji_id, [:string], :optional}],
    true,
    "Use this method to set the thumbnail of a custom emoji sticker set. Returns True on success."
  )

  method(
    :post,
    "deleteStickerSet",
    [{name, [:string]}],
    true,
    "Use this method to delete a sticker set that was created by the bot. Returns True on success."
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
      {button, [InlineQueryResultsButton], :optional}
    ],
    true,
    "Use this method to send answers to an inline query. On success, True is returned. No more than 50 results per query are allowed."
  )

  method(
    :post,
    "answerWebAppQuery",
    [{web_app_query_id, [:string]}, {result, [InlineQueryResult]}],
    ExGram.Model.SentWebAppMessage,
    "Use this method to set the result of an interaction with a Web App and send a corresponding message on behalf of the user to the chat from which the query originated. On success, a SentWebAppMessage object is returned."
  )

  method(
    :post,
    "sendInvoice",
    [
      {chat_id, [:integer, :string]},
      {message_thread_id, [:integer], :optional},
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
      {reply_parameters, [ReplyParameters], :optional},
      {reply_markup, [InlineKeyboardMarkup], :optional}
    ],
    ExGram.Model.Message,
    "Use this method to send invoices. On success, the sent Message is returned."
  )

  method(
    :post,
    "createInvoiceLink",
    [
      {title, [:string]},
      {description, [:string]},
      {payload, [:string]},
      {provider_token, [:string]},
      {currency, [:string]},
      {prices, [{:array, LabeledPrice}]},
      {max_tip_amount, [:integer], :optional},
      {suggested_tip_amounts, [{:array, :integer}], :optional},
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
      {is_flexible, [:boolean], :optional}
    ],
    :string,
    "Use this method to create a link for an invoice. Returns the created invoice link as String on success."
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
      {message_thread_id, [:integer], :optional},
      {game_short_name, [:string]},
      {disable_notification, [:boolean], :optional},
      {protect_content, [:boolean], :optional},
      {reply_parameters, [ReplyParameters], :optional},
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
    {:array, ExGram.Model.GameHighScore},
    "Use this method to get data for high score tables. Will return the score of the specified user and several of their neighbors in a game. Returns an Array of GameHighScore objects."
  )

  # 119 methods

  # ----------MODELS-----------

  # Models

  defmodule Model do
    @moduledoc """
    Telegram API Model structures
    """

    model(
      Update,
      [
        {:update_id, [:integer]},
        {:message, [Message], :optional},
        {:edited_message, [Message], :optional},
        {:channel_post, [Message], :optional},
        {:edited_channel_post, [Message], :optional},
        {:message_reaction, [MessageReactionUpdated], :optional},
        {:message_reaction_count, [MessageReactionCountUpdated], :optional},
        {:inline_query, [InlineQuery], :optional},
        {:chosen_inline_result, [ChosenInlineResult], :optional},
        {:callback_query, [CallbackQuery], :optional},
        {:shipping_query, [ShippingQuery], :optional},
        {:pre_checkout_query, [PreCheckoutQuery], :optional},
        {:poll, [Poll], :optional},
        {:poll_answer, [PollAnswer], :optional},
        {:my_chat_member, [ChatMemberUpdated], :optional},
        {:chat_member, [ChatMemberUpdated], :optional},
        {:chat_join_request, [ChatJoinRequest], :optional},
        {:chat_boost, [ChatBoostUpdated], :optional},
        {:removed_chat_boost, [ChatBoostRemoved], :optional}
      ],
      "This object represents an incoming update. At most one of the optional parameters can be present in any given update."
    )

    model(
      WebhookInfo,
      [
        {:url, [:string]},
        {:has_custom_certificate, [:boolean]},
        {:pending_update_count, [:integer]},
        {:ip_address, [:string], :optional},
        {:last_error_date, [:integer], :optional},
        {:last_error_message, [:string], :optional},
        {:last_synchronization_error_date, [:integer], :optional},
        {:max_connections, [:integer], :optional},
        {:allowed_updates, [{:array, :string}], :optional}
      ],
      "Describes the current status of a webhook."
    )

    model(
      User,
      [
        {:id, [:integer]},
        {:is_bot, [:boolean]},
        {:first_name, [:string]},
        {:last_name, [:string], :optional},
        {:username, [:string], :optional},
        {:language_code, [:string], :optional},
        {:is_premium, [:boolean], :optional},
        {:added_to_attachment_menu, [:boolean], :optional},
        {:can_join_groups, [:boolean], :optional},
        {:can_read_all_group_messages, [:boolean], :optional},
        {:supports_inline_queries, [:boolean], :optional}
      ],
      "This object represents a Telegram user or bot."
    )

    model(
      Chat,
      [
        {:id, [:integer]},
        {:type, [:string]},
        {:title, [:string], :optional},
        {:username, [:string], :optional},
        {:first_name, [:string], :optional},
        {:last_name, [:string], :optional},
        {:is_forum, [:boolean], :optional},
        {:photo, [ChatPhoto], :optional},
        {:active_usernames, [{:array, :string}], :optional},
        {:available_reactions, [{:array, ReactionType}], :optional},
        {:accent_color_id, [:integer], :optional},
        {:background_custom_emoji_id, [:string], :optional},
        {:profile_accent_color_id, [:integer], :optional},
        {:profile_background_custom_emoji_id, [:string], :optional},
        {:emoji_status_custom_emoji_id, [:string], :optional},
        {:emoji_status_expiration_date, [:integer], :optional},
        {:bio, [:string], :optional},
        {:has_private_forwards, [:boolean], :optional},
        {:has_restricted_voice_and_video_messages, [:boolean], :optional},
        {:join_to_send_messages, [:boolean], :optional},
        {:join_by_request, [:boolean], :optional},
        {:description, [:string], :optional},
        {:invite_link, [:string], :optional},
        {:pinned_message, [Message], :optional},
        {:permissions, [ChatPermissions], :optional},
        {:slow_mode_delay, [:integer], :optional},
        {:message_auto_delete_time, [:integer], :optional},
        {:has_aggressive_anti_spam_enabled, [:boolean], :optional},
        {:has_hidden_members, [:boolean], :optional},
        {:has_protected_content, [:boolean], :optional},
        {:has_visible_history, [:boolean], :optional},
        {:sticker_set_name, [:string], :optional},
        {:can_set_sticker_set, [:boolean], :optional},
        {:linked_chat_id, [:integer], :optional},
        {:location, [ChatLocation], :optional}
      ],
      "This object represents a chat."
    )

    model(
      Message,
      [
        {:message_id, [:integer]},
        {:message_thread_id, [:integer], :optional},
        {:from, [User], :optional},
        {:sender_chat, [Chat], :optional},
        {:date, [:integer]},
        {:chat, [Chat]},
        {:forward_origin, [MessageOrigin], :optional},
        {:is_topic_message, [:boolean], :optional},
        {:is_automatic_forward, [:boolean], :optional},
        {:reply_to_message, [Message], :optional},
        {:external_reply, [ExternalReplyInfo], :optional},
        {:quote, [TextQuote], :optional},
        {:via_bot, [User], :optional},
        {:edit_date, [:integer], :optional},
        {:has_protected_content, [:boolean], :optional},
        {:media_group_id, [:string], :optional},
        {:author_signature, [:string], :optional},
        {:text, [:string], :optional},
        {:entities, [{:array, MessageEntity}], :optional},
        {:link_preview_options, [LinkPreviewOptions], :optional},
        {:animation, [Animation], :optional},
        {:audio, [Audio], :optional},
        {:document, [Document], :optional},
        {:photo, [{:array, PhotoSize}], :optional},
        {:sticker, [Sticker], :optional},
        {:story, [Story], :optional},
        {:video, [Video], :optional},
        {:video_note, [VideoNote], :optional},
        {:voice, [Voice], :optional},
        {:caption, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:has_media_spoiler, [:boolean], :optional},
        {:contact, [Contact], :optional},
        {:dice, [Dice], :optional},
        {:game, [Game], :optional},
        {:poll, [Poll], :optional},
        {:venue, [Venue], :optional},
        {:location, [Location], :optional},
        {:new_chat_members, [{:array, User}], :optional},
        {:left_chat_member, [User], :optional},
        {:new_chat_title, [:string], :optional},
        {:new_chat_photo, [{:array, PhotoSize}], :optional},
        {:delete_chat_photo, [:boolean], :optional},
        {:group_chat_created, [:boolean], :optional},
        {:supergroup_chat_created, [:boolean], :optional},
        {:channel_chat_created, [:boolean], :optional},
        {:message_auto_delete_timer_changed, [MessageAutoDeleteTimerChanged], :optional},
        {:migrate_to_chat_id, [:integer], :optional},
        {:migrate_from_chat_id, [:integer], :optional},
        {:pinned_message, [MaybeInaccessibleMessage], :optional},
        {:invoice, [Invoice], :optional},
        {:successful_payment, [SuccessfulPayment], :optional},
        {:users_shared, [UsersShared], :optional},
        {:chat_shared, [ChatShared], :optional},
        {:connected_website, [:string], :optional},
        {:write_access_allowed, [WriteAccessAllowed], :optional},
        {:passport_data, [PassportData], :optional},
        {:proximity_alert_triggered, [ProximityAlertTriggered], :optional},
        {:forum_topic_created, [ForumTopicCreated], :optional},
        {:forum_topic_edited, [ForumTopicEdited], :optional},
        {:forum_topic_closed, [ForumTopicClosed], :optional},
        {:forum_topic_reopened, [ForumTopicReopened], :optional},
        {:general_forum_topic_hidden, [GeneralForumTopicHidden], :optional},
        {:general_forum_topic_unhidden, [GeneralForumTopicUnhidden], :optional},
        {:giveaway_created, [GiveawayCreated], :optional},
        {:giveaway, [Giveaway], :optional},
        {:giveaway_winners, [GiveawayWinners], :optional},
        {:giveaway_completed, [GiveawayCompleted], :optional},
        {:video_chat_scheduled, [VideoChatScheduled], :optional},
        {:video_chat_started, [VideoChatStarted], :optional},
        {:video_chat_ended, [VideoChatEnded], :optional},
        {:video_chat_participants_invited, [VideoChatParticipantsInvited], :optional},
        {:web_app_data, [WebAppData], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional}
      ],
      "This object represents a message."
    )

    model(MessageId, [{:message_id, [:integer]}], "This object represents a unique message identifier.")

    model(
      InaccessibleMessage,
      [{:chat, [Chat]}, {:message_id, [:integer]}, {:date, [:integer]}],
      "This object describes a message that was deleted or is otherwise inaccessible to the bot."
    )

    model(
      MaybeInaccessibleMessage,
      [
        {:type, [:string]},
        {:offset, [:integer]},
        {:length, [:integer]},
        {:url, [:string], :optional},
        {:user, [User], :optional},
        {:language, [:string], :optional},
        {:custom_emoji_id, [:string], :optional}
      ],
      "This object describes a message that can be inaccessible to the bot. It can be one of"
    )

    model(
      MessageEntity,
      [
        {:type, [:string]},
        {:offset, [:integer]},
        {:length, [:integer]},
        {:url, [:string], :optional},
        {:user, [User], :optional},
        {:language, [:string], :optional},
        {:custom_emoji_id, [:string], :optional}
      ],
      "This object represents one special entity in a text message. For example, hashtags, usernames, URLs, etc."
    )

    model(
      TextQuote,
      [
        {:text, [:string]},
        {:entities, [{:array, MessageEntity}], :optional},
        {:position, [:integer]},
        {:is_manual, [:boolean], :optional}
      ],
      "This object contains information about the quoted part of a message that is replied to by the given message."
    )

    model(
      ExternalReplyInfo,
      [
        {:origin, [MessageOrigin]},
        {:chat, [Chat], :optional},
        {:message_id, [:integer], :optional},
        {:link_preview_options, [LinkPreviewOptions], :optional},
        {:animation, [Animation], :optional},
        {:audio, [Audio], :optional},
        {:document, [Document], :optional},
        {:photo, [{:array, PhotoSize}], :optional},
        {:sticker, [Sticker], :optional},
        {:story, [Story], :optional},
        {:video, [Video], :optional},
        {:video_note, [VideoNote], :optional},
        {:voice, [Voice], :optional},
        {:has_media_spoiler, [:boolean], :optional},
        {:contact, [Contact], :optional},
        {:dice, [Dice], :optional},
        {:game, [Game], :optional},
        {:giveaway, [Giveaway], :optional},
        {:giveaway_winners, [GiveawayWinners], :optional},
        {:invoice, [Invoice], :optional},
        {:location, [Location], :optional},
        {:poll, [Poll], :optional},
        {:venue, [Venue], :optional}
      ],
      "This object contains information about a message that is being replied to, which may come from another chat or forum topic."
    )

    model(
      ReplyParameters,
      [
        {:message_id, [:integer]},
        {:chat_id, [:integer, :string], :optional},
        {:allow_sending_without_reply, [:boolean], :optional},
        {:quote, [:string], :optional},
        {:quote_parse_mode, [:string], :optional},
        {:quote_entities, [{:array, MessageEntity}], :optional},
        {:quote_position, [:integer], :optional}
      ],
      "Describes reply parameters for the message that is being sent."
    )

    model(
      MessageOrigin,
      [{:type, [:string]}, {:date, [:integer]}, {:sender_user, [User]}],
      "This object describes the origin of a message. It can be one of"
    )

    model(
      MessageOriginUser,
      [{:type, [:string]}, {:date, [:integer]}, {:sender_user, [User]}],
      "The message was originally sent by a known user."
    )

    model(
      MessageOriginHiddenUser,
      [{:type, [:string]}, {:date, [:integer]}, {:sender_user_name, [:string]}],
      "The message was originally sent by an unknown user."
    )

    model(
      MessageOriginChat,
      [{:type, [:string]}, {:date, [:integer]}, {:sender_chat, [Chat]}, {:author_signature, [:string], :optional}],
      "The message was originally sent on behalf of a chat to a group chat."
    )

    model(
      MessageOriginChannel,
      [
        {:type, [:string]},
        {:date, [:integer]},
        {:chat, [Chat]},
        {:message_id, [:integer]},
        {:author_signature, [:string], :optional}
      ],
      "The message was originally sent to a channel chat."
    )

    model(
      PhotoSize,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:width, [:integer]},
        {:height, [:integer]},
        {:file_size, [:integer], :optional}
      ],
      "This object represents one size of a photo or a file / sticker thumbnail."
    )

    model(
      Animation,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:width, [:integer]},
        {:height, [:integer]},
        {:duration, [:integer]},
        {:thumbnail, [PhotoSize], :optional},
        {:file_name, [:string], :optional},
        {:mime_type, [:string], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents an animation file (GIF or H.264/MPEG-4 AVC video without sound)."
    )

    model(
      Audio,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:duration, [:integer]},
        {:performer, [:string], :optional},
        {:title, [:string], :optional},
        {:file_name, [:string], :optional},
        {:mime_type, [:string], :optional},
        {:file_size, [:integer], :optional},
        {:thumbnail, [PhotoSize], :optional}
      ],
      "This object represents an audio file to be treated as music by the Telegram clients."
    )

    model(
      Document,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:thumbnail, [PhotoSize], :optional},
        {:file_name, [:string], :optional},
        {:mime_type, [:string], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents a general file (as opposed to photos, voice messages and audio files)."
    )

    model(
      Story,
      [],
      "This object represents a message about a forwarded story in the chat. Currently holds no information."
    )

    model(
      Video,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:width, [:integer]},
        {:height, [:integer]},
        {:duration, [:integer]},
        {:thumbnail, [PhotoSize], :optional},
        {:file_name, [:string], :optional},
        {:mime_type, [:string], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents a video file."
    )

    model(
      VideoNote,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:length, [:integer]},
        {:duration, [:integer]},
        {:thumbnail, [PhotoSize], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents a video message (available in Telegram apps as of v.4.0)."
    )

    model(
      Voice,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:duration, [:integer]},
        {:mime_type, [:string], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents a voice note."
    )

    model(
      Contact,
      [
        {:phone_number, [:string]},
        {:first_name, [:string]},
        {:last_name, [:string], :optional},
        {:user_id, [:integer], :optional},
        {:vcard, [:string], :optional}
      ],
      "This object represents a phone contact."
    )

    model(
      Dice,
      [{:emoji, [:string]}, {:value, [:integer]}],
      "This object represents an animated emoji that displays a random value."
    )

    model(
      PollOption,
      [{:text, [:string]}, {:voter_count, [:integer]}],
      "This object contains information about one answer option in a poll."
    )

    model(
      PollAnswer,
      [
        {:poll_id, [:string]},
        {:voter_chat, [Chat], :optional},
        {:user, [User], :optional},
        {:option_ids, [{:array, :integer}]}
      ],
      "This object represents an answer of a user in a non-anonymous poll."
    )

    model(
      Poll,
      [
        {:id, [:string]},
        {:question, [:string]},
        {:options, [{:array, PollOption}]},
        {:total_voter_count, [:integer]},
        {:is_closed, [:boolean]},
        {:is_anonymous, [:boolean]},
        {:type, [:string]},
        {:allows_multiple_answers, [:boolean]},
        {:correct_option_id, [:integer], :optional},
        {:explanation, [:string], :optional},
        {:explanation_entities, [{:array, MessageEntity}], :optional},
        {:open_period, [:integer], :optional},
        {:close_date, [:integer], :optional}
      ],
      "This object contains information about a poll."
    )

    model(
      Location,
      [
        {:longitude, [:float]},
        {:latitude, [:float]},
        {:horizontal_accuracy, [:float], :optional},
        {:live_period, [:integer], :optional},
        {:heading, [:integer], :optional},
        {:proximity_alert_radius, [:integer], :optional}
      ],
      "This object represents a point on the map."
    )

    model(
      Venue,
      [
        {:location, [Location]},
        {:title, [:string]},
        {:address, [:string]},
        {:foursquare_id, [:string], :optional},
        {:foursquare_type, [:string], :optional},
        {:google_place_id, [:string], :optional},
        {:google_place_type, [:string], :optional}
      ],
      "This object represents a venue."
    )

    model(WebAppData, [{:data, [:string]}, {:button_text, [:string]}], "Describes data sent from a Web App to the bot.")

    model(
      ProximityAlertTriggered,
      [{:traveler, [User]}, {:watcher, [User]}, {:distance, [:integer]}],
      "This object represents the content of a service message, sent whenever a user in the chat triggers a proximity alert set by another user."
    )

    model(
      MessageAutoDeleteTimerChanged,
      [{:message_auto_delete_time, [:integer]}],
      "This object represents a service message about a change in auto-delete timer settings."
    )

    model(
      ForumTopicCreated,
      [{:name, [:string]}, {:icon_color, [:integer]}, {:icon_custom_emoji_id, [:string], :optional}],
      "This object represents a service message about a new forum topic created in the chat."
    )

    model(
      ForumTopicClosed,
      [],
      "This object represents a service message about a forum topic closed in the chat. Currently holds no information."
    )

    model(
      ForumTopicEdited,
      [{:name, [:string], :optional}, {:icon_custom_emoji_id, [:string], :optional}],
      "This object represents a service message about an edited forum topic."
    )

    model(
      ForumTopicReopened,
      [],
      "This object represents a service message about a forum topic reopened in the chat. Currently holds no information."
    )

    model(
      GeneralForumTopicHidden,
      [],
      "This object represents a service message about General forum topic hidden in the chat. Currently holds no information."
    )

    model(
      GeneralForumTopicUnhidden,
      [],
      "This object represents a service message about General forum topic unhidden in the chat. Currently holds no information."
    )

    model(
      UsersShared,
      [{:request_id, [:integer]}, {:user_ids, [{:array, :integer}]}],
      "This object contains information about the users whose identifiers were shared with the bot using a KeyboardButtonRequestUsers button."
    )

    model(
      ChatShared,
      [{:request_id, [:integer]}, {:chat_id, [:integer]}],
      "This object contains information about the chat whose identifier was shared with the bot using a KeyboardButtonRequestChat button."
    )

    model(
      WriteAccessAllowed,
      [
        {:from_request, [:boolean], :optional},
        {:web_app_name, [:string], :optional},
        {:from_attachment_menu, [:boolean], :optional}
      ],
      "This object represents a service message about a user allowing a bot to write messages after adding it to the attachment menu, launching a Web App from a link, or accepting an explicit request from a Web App sent by the method requestWriteAccess."
    )

    model(
      VideoChatScheduled,
      [{:start_date, [:integer]}],
      "This object represents a service message about a video chat scheduled in the chat."
    )

    model(
      VideoChatStarted,
      [],
      "This object represents a service message about a video chat started in the chat. Currently holds no information."
    )

    model(
      VideoChatEnded,
      [{:duration, [:integer]}],
      "This object represents a service message about a video chat ended in the chat."
    )

    model(
      VideoChatParticipantsInvited,
      [{:users, [{:array, User}]}],
      "This object represents a service message about new members invited to a video chat."
    )

    model(
      GiveawayCreated,
      [],
      "This object represents a service message about the creation of a scheduled giveaway. Currently holds no information."
    )

    model(
      Giveaway,
      [
        {:chats, [{:array, Chat}]},
        {:winners_selection_date, [:integer]},
        {:winner_count, [:integer]},
        {:only_new_members, [:boolean], :optional},
        {:has_public_winners, [:boolean], :optional},
        {:prize_description, [:string], :optional},
        {:country_codes, [{:array, :string}], :optional},
        {:premium_subscription_month_count, [:integer], :optional}
      ],
      "This object represents a message about a scheduled giveaway."
    )

    model(
      GiveawayWinners,
      [
        {:chat, [Chat]},
        {:giveaway_message_id, [:integer]},
        {:winners_selection_date, [:integer]},
        {:winner_count, [:integer]},
        {:winners, [{:array, User}]},
        {:additional_chat_count, [:integer], :optional},
        {:premium_subscription_month_count, [:integer], :optional},
        {:unclaimed_prize_count, [:integer], :optional},
        {:only_new_members, [:boolean], :optional},
        {:was_refunded, [:boolean], :optional},
        {:prize_description, [:string], :optional}
      ],
      "This object represents a message about the completion of a giveaway with public winners."
    )

    model(
      GiveawayCompleted,
      [
        {:winner_count, [:integer]},
        {:unclaimed_prize_count, [:integer], :optional},
        {:giveaway_message, [Message], :optional}
      ],
      "This object represents a service message about the completion of a giveaway without public winners."
    )

    model(
      LinkPreviewOptions,
      [
        {:is_disabled, [:boolean], :optional},
        {:url, [:string], :optional},
        {:prefer_small_media, [:boolean], :optional},
        {:prefer_large_media, [:boolean], :optional},
        {:show_above_text, [:boolean], :optional}
      ],
      "Describes the options used for link preview generation."
    )

    model(
      UserProfilePhotos,
      [{:total_count, [:integer]}, {:photos, [{:array, {:array, PhotoSize}}]}],
      "This object represent a user's profile pictures."
    )

    model(
      File,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:file_size, [:integer], :optional},
        {:file_path, [:string], :optional}
      ],
      "This object represents a file ready to be downloaded. The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile."
    )

    model(WebAppInfo, [{:url, [:string]}], "Describes a Web App.")

    model(
      ReplyKeyboardMarkup,
      [
        {:keyboard, [{:array, {:array, KeyboardButton}}]},
        {:is_persistent, [:boolean], :optional},
        {:resize_keyboard, [:boolean], :optional},
        {:one_time_keyboard, [:boolean], :optional},
        {:input_field_placeholder, [:string], :optional},
        {:selective, [:boolean], :optional}
      ],
      "This object represents a custom keyboard with reply options (see Introduction to bots for details and examples)."
    )

    model(
      KeyboardButton,
      [
        {:text, [:string]},
        {:request_users, [KeyboardButtonRequestUsers], :optional},
        {:request_chat, [KeyboardButtonRequestChat], :optional},
        {:request_contact, [:boolean], :optional},
        {:request_location, [:boolean], :optional},
        {:request_poll, [KeyboardButtonPollType], :optional},
        {:web_app, [WebAppInfo], :optional}
      ],
      "This object represents one button of the reply keyboard. For simple text buttons, String can be used instead of this object to specify the button text. The optional fields web_app, request_user, request_chat, request_contact, request_location, and request_poll are mutually exclusive."
    )

    model(
      KeyboardButtonRequestUsers,
      [
        {:request_id, [:integer]},
        {:user_is_bot, [:boolean], :optional},
        {:user_is_premium, [:boolean], :optional},
        {:max_quantity, [:integer], :optional}
      ],
      "This object defines the criteria used to request suitable users. The identifiers of the selected users will be shared with the bot when the corresponding button is pressed. More about requesting users »"
    )

    model(
      KeyboardButtonRequestChat,
      [
        {:request_id, [:integer]},
        {:chat_is_channel, [:boolean]},
        {:chat_is_forum, [:boolean], :optional},
        {:chat_has_username, [:boolean], :optional},
        {:chat_is_created, [:boolean], :optional},
        {:user_administrator_rights, [ChatAdministratorRights], :optional},
        {:bot_administrator_rights, [ChatAdministratorRights], :optional},
        {:bot_is_member, [:boolean], :optional}
      ],
      "This object defines the criteria used to request a suitable chat. The identifier of the selected chat will be shared with the bot when the corresponding button is pressed. More about requesting chats »"
    )

    model(
      KeyboardButtonPollType,
      [{:type, [:string], :optional}],
      "This object represents type of a poll, which is allowed to be created and sent when the corresponding button is pressed."
    )

    model(
      ReplyKeyboardRemove,
      [{:remove_keyboard, [:boolean]}, {:selective, [:boolean], :optional}],
      "Upon receiving a message with this object, Telegram clients will remove the current custom keyboard and display the default letter-keyboard. By default, custom keyboards are displayed until a new keyboard is sent by a bot. An exception is made for one-time keyboards that are hidden immediately after the user presses a button (see ReplyKeyboardMarkup)."
    )

    model(
      InlineKeyboardMarkup,
      [{:inline_keyboard, [{:array, {:array, InlineKeyboardButton}}]}],
      "This object represents an inline keyboard that appears right next to the message it belongs to."
    )

    model(
      InlineKeyboardButton,
      [
        {:text, [:string]},
        {:url, [:string], :optional},
        {:callback_data, [:string], :optional},
        {:web_app, [WebAppInfo], :optional},
        {:login_url, [LoginUrl], :optional},
        {:switch_inline_query, [:string], :optional},
        {:switch_inline_query_current_chat, [:string], :optional},
        {:switch_inline_query_chosen_chat, [SwitchInlineQueryChosenChat], :optional},
        {:callback_game, [CallbackGame], :optional},
        {:pay, [:boolean], :optional}
      ],
      "This object represents one button of an inline keyboard. You must use exactly one of the optional fields."
    )

    model(
      LoginUrl,
      [
        {:url, [:string]},
        {:forward_text, [:string], :optional},
        {:bot_username, [:string], :optional},
        {:request_write_access, [:boolean], :optional}
      ],
      "This object represents a parameter of the inline keyboard button used to automatically authorize a user. Serves as a great replacement for the Telegram Login Widget when the user is coming from Telegram. All the user needs to do is tap/click a button and confirm that they want to log in:"
    )

    model(
      SwitchInlineQueryChosenChat,
      [
        {:query, [:string], :optional},
        {:allow_user_chats, [:boolean], :optional},
        {:allow_bot_chats, [:boolean], :optional},
        {:allow_group_chats, [:boolean], :optional},
        {:allow_channel_chats, [:boolean], :optional}
      ],
      "This object represents an inline button that switches the current user to inline mode in a chosen chat, with an optional default inline query."
    )

    model(
      CallbackQuery,
      [
        {:id, [:string]},
        {:from, [User]},
        {:message, [MaybeInaccessibleMessage], :optional},
        {:inline_message_id, [:string], :optional},
        {:chat_instance, [:string]},
        {:data, [:string], :optional},
        {:game_short_name, [:string], :optional}
      ],
      "This object represents an incoming callback query from a callback button in an inline keyboard. If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present."
    )

    model(
      ForceReply,
      [
        {:force_reply, [:boolean]},
        {:input_field_placeholder, [:string], :optional},
        {:selective, [:boolean], :optional}
      ],
      "Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot's message and tapped 'Reply'). This can be extremely useful if you want to create user-friendly step-by-step interfaces without having to sacrifice privacy mode."
    )

    model(
      ChatPhoto,
      [
        {:small_file_id, [:string]},
        {:small_file_unique_id, [:string]},
        {:big_file_id, [:string]},
        {:big_file_unique_id, [:string]}
      ],
      "This object represents a chat photo."
    )

    model(
      ChatInviteLink,
      [
        {:invite_link, [:string]},
        {:creator, [User]},
        {:creates_join_request, [:boolean]},
        {:is_primary, [:boolean]},
        {:is_revoked, [:boolean]},
        {:name, [:string], :optional},
        {:expire_date, [:integer], :optional},
        {:member_limit, [:integer], :optional},
        {:pending_join_request_count, [:integer], :optional}
      ],
      "Represents an invite link for a chat."
    )

    model(
      ChatAdministratorRights,
      [
        {:is_anonymous, [:boolean]},
        {:can_manage_chat, [:boolean]},
        {:can_delete_messages, [:boolean]},
        {:can_manage_video_chats, [:boolean]},
        {:can_restrict_members, [:boolean]},
        {:can_promote_members, [:boolean]},
        {:can_change_info, [:boolean]},
        {:can_invite_users, [:boolean]},
        {:can_post_messages, [:boolean], :optional},
        {:can_edit_messages, [:boolean], :optional},
        {:can_pin_messages, [:boolean], :optional},
        {:can_post_stories, [:boolean], :optional},
        {:can_edit_stories, [:boolean], :optional},
        {:can_delete_stories, [:boolean], :optional},
        {:can_manage_topics, [:boolean], :optional}
      ],
      "Represents the rights of an administrator in a chat."
    )

    model(
      ChatMemberUpdated,
      [
        {:chat, [Chat]},
        {:from, [User]},
        {:date, [:integer]},
        {:old_chat_member, [ChatMember]},
        {:new_chat_member, [ChatMember]},
        {:invite_link, [ChatInviteLink], :optional},
        {:via_chat_folder_invite_link, [:boolean], :optional}
      ],
      "This object represents changes in the status of a chat member."
    )

    model(
      ChatMemberOwner,
      [{:status, [:string]}, {:user, [User]}, {:is_anonymous, [:boolean]}, {:custom_title, [:string], :optional}],
      "Represents a chat member that owns the chat and has all administrator privileges."
    )

    model(
      ChatMemberAdministrator,
      [
        {:status, [:string]},
        {:user, [User]},
        {:can_be_edited, [:boolean]},
        {:is_anonymous, [:boolean]},
        {:can_manage_chat, [:boolean]},
        {:can_delete_messages, [:boolean]},
        {:can_manage_video_chats, [:boolean]},
        {:can_restrict_members, [:boolean]},
        {:can_promote_members, [:boolean]},
        {:can_change_info, [:boolean]},
        {:can_invite_users, [:boolean]},
        {:can_post_messages, [:boolean], :optional},
        {:can_edit_messages, [:boolean], :optional},
        {:can_pin_messages, [:boolean], :optional},
        {:can_post_stories, [:boolean], :optional},
        {:can_edit_stories, [:boolean], :optional},
        {:can_delete_stories, [:boolean], :optional},
        {:can_manage_topics, [:boolean], :optional},
        {:custom_title, [:string], :optional}
      ],
      "Represents a chat member that has some additional privileges."
    )

    model(
      ChatMemberMember,
      [{:status, [:string]}, {:user, [User]}],
      "Represents a chat member that has no additional privileges or restrictions."
    )

    model(
      ChatMemberRestricted,
      [
        {:status, [:string]},
        {:user, [User]},
        {:is_member, [:boolean]},
        {:can_send_messages, [:boolean]},
        {:can_send_audios, [:boolean]},
        {:can_send_documents, [:boolean]},
        {:can_send_photos, [:boolean]},
        {:can_send_videos, [:boolean]},
        {:can_send_video_notes, [:boolean]},
        {:can_send_voice_notes, [:boolean]},
        {:can_send_polls, [:boolean]},
        {:can_send_other_messages, [:boolean]},
        {:can_add_web_page_previews, [:boolean]},
        {:can_change_info, [:boolean]},
        {:can_invite_users, [:boolean]},
        {:can_pin_messages, [:boolean]},
        {:can_manage_topics, [:boolean]},
        {:until_date, [:integer]}
      ],
      "Represents a chat member that is under certain restrictions in the chat. Supergroups only."
    )

    model(
      ChatMemberLeft,
      [{:status, [:string]}, {:user, [User]}],
      "Represents a chat member that isn't currently a member of the chat, but may join it themselves."
    )

    model(
      ChatMemberBanned,
      [{:status, [:string]}, {:user, [User]}, {:until_date, [:integer]}],
      "Represents a chat member that was banned in the chat and can't return to the chat or view chat messages."
    )

    model(
      ChatJoinRequest,
      [
        {:chat, [Chat]},
        {:from, [User]},
        {:user_chat_id, [:integer]},
        {:date, [:integer]},
        {:bio, [:string], :optional},
        {:invite_link, [ChatInviteLink], :optional}
      ],
      "Represents a join request sent to a chat."
    )

    model(
      ChatPermissions,
      [
        {:can_send_messages, [:boolean], :optional},
        {:can_send_audios, [:boolean], :optional},
        {:can_send_documents, [:boolean], :optional},
        {:can_send_photos, [:boolean], :optional},
        {:can_send_videos, [:boolean], :optional},
        {:can_send_video_notes, [:boolean], :optional},
        {:can_send_voice_notes, [:boolean], :optional},
        {:can_send_polls, [:boolean], :optional},
        {:can_send_other_messages, [:boolean], :optional},
        {:can_add_web_page_previews, [:boolean], :optional},
        {:can_change_info, [:boolean], :optional},
        {:can_invite_users, [:boolean], :optional},
        {:can_pin_messages, [:boolean], :optional},
        {:can_manage_topics, [:boolean], :optional}
      ],
      "Describes actions that a non-administrator user is allowed to take in a chat."
    )

    model(
      ChatLocation,
      [{:location, [Location]}, {:address, [:string]}],
      "Represents a location to which a chat is connected."
    )

    model(
      ReactionType,
      [{:type, [:string]}, {:emoji, [:string]}],
      "This object describes the type of a reaction. Currently, it can be one of"
    )

    model(ReactionTypeEmoji, [{:type, [:string]}, {:emoji, [:string]}], "The reaction is based on an emoji.")

    model(
      ReactionTypeCustomEmoji,
      [{:type, [:string]}, {:custom_emoji, [:string]}],
      "The reaction is based on a custom emoji."
    )

    model(
      ReactionCount,
      [{:type, [ReactionType]}, {:total_count, [:integer]}],
      "Represents a reaction added to a message along with the number of times it was added."
    )

    model(
      MessageReactionUpdated,
      [
        {:chat, [Chat]},
        {:message_id, [:integer]},
        {:user, [User], :optional},
        {:actor_chat, [Chat], :optional},
        {:date, [:integer]},
        {:old_reaction, [{:array, ReactionType}]},
        {:new_reaction, [{:array, ReactionType}]}
      ],
      "This object represents a change of a reaction on a message performed by a user."
    )

    model(
      MessageReactionCountUpdated,
      [{:chat, [Chat]}, {:message_id, [:integer]}, {:date, [:integer]}, {:reactions, [{:array, ReactionCount}]}],
      "This object represents reaction changes on a message with anonymous reactions."
    )

    model(
      ForumTopic,
      [
        {:message_thread_id, [:integer]},
        {:name, [:string]},
        {:icon_color, [:integer]},
        {:icon_custom_emoji_id, [:string], :optional}
      ],
      "This object represents a forum topic."
    )

    model(BotCommand, [{:command, [:string]}, {:description, [:string]}], "This object represents a bot command.")

    model(
      BotCommandScopeDefault,
      [{:type, [:string]}],
      "Represents the default scope of bot commands. Default commands are used if no commands with a narrower scope are specified for the user."
    )

    model(
      BotCommandScopeAllPrivateChats,
      [{:type, [:string]}],
      "Represents the scope of bot commands, covering all private chats."
    )

    model(
      BotCommandScopeAllGroupChats,
      [{:type, [:string]}],
      "Represents the scope of bot commands, covering all group and supergroup chats."
    )

    model(
      BotCommandScopeAllChatAdministrators,
      [{:type, [:string]}],
      "Represents the scope of bot commands, covering all group and supergroup chat administrators."
    )

    model(
      BotCommandScopeChat,
      [{:type, [:string]}, {:chat_id, [:integer, :string]}],
      "Represents the scope of bot commands, covering a specific chat."
    )

    model(
      BotCommandScopeChatAdministrators,
      [{:type, [:string]}, {:chat_id, [:integer, :string]}],
      "Represents the scope of bot commands, covering all administrators of a specific group or supergroup chat."
    )

    model(
      BotCommandScopeChatMember,
      [{:type, [:string]}, {:chat_id, [:integer, :string]}, {:user_id, [:integer]}],
      "Represents the scope of bot commands, covering a specific member of a group or supergroup chat."
    )

    model(BotName, [{:name, [:string]}], "This object represents the bot's name.")

    model(BotDescription, [{:description, [:string]}], "This object represents the bot's description.")

    model(BotShortDescription, [{:short_description, [:string]}], "This object represents the bot's short description.")

    model(MenuButtonCommands, [{:type, [:string]}], "Represents a menu button, which opens the bot's list of commands.")

    model(
      MenuButtonWebApp,
      [{:type, [:string]}, {:text, [:string]}, {:web_app, [WebAppInfo]}],
      "Represents a menu button, which launches a Web App."
    )

    model(MenuButtonDefault, [{:type, [:string]}], "Describes that no specific value for the menu button was set.")

    model(
      ChatBoostSource,
      [{:source, [:string]}, {:user, [User]}],
      "This object describes the source of a chat boost. It can be one of"
    )

    model(
      ChatBoostSourcePremium,
      [{:source, [:string]}, {:user, [User]}],
      "The boost was obtained by subscribing to Telegram Premium or by gifting a Telegram Premium subscription to another user."
    )

    model(
      ChatBoostSourceGiftCode,
      [{:source, [:string]}, {:user, [User]}],
      "The boost was obtained by the creation of Telegram Premium gift codes to boost a chat. Each such code boosts the chat 4 times for the duration of the corresponding Telegram Premium subscription."
    )

    model(
      ChatBoostSourceGiveaway,
      [
        {:source, [:string]},
        {:giveaway_message_id, [:integer]},
        {:user, [User], :optional},
        {:is_unclaimed, [:boolean], :optional}
      ],
      "The boost was obtained by the creation of a Telegram Premium giveaway. This boosts the chat 4 times for the duration of the corresponding Telegram Premium subscription."
    )

    model(
      ChatBoost,
      [{:boost_id, [:string]}, {:add_date, [:integer]}, {:expiration_date, [:integer]}, {:source, [ChatBoostSource]}],
      "This object contains information about a chat boost."
    )

    model(
      ChatBoostUpdated,
      [{:chat, [Chat]}, {:boost, [ChatBoost]}],
      "This object represents a boost added to a chat or changed."
    )

    model(
      ChatBoostRemoved,
      [{:chat, [Chat]}, {:boost_id, [:string]}, {:remove_date, [:integer]}, {:source, [ChatBoostSource]}],
      "This object represents a boost removed from a chat."
    )

    model(
      UserChatBoosts,
      [{:boosts, [{:array, ChatBoost}]}],
      "This object represents a list of boosts added to a chat by a user."
    )

    model(
      ResponseParameters,
      [{:migrate_to_chat_id, [:integer], :optional}, {:retry_after, [:integer], :optional}],
      "Describes why a request was unsuccessful."
    )

    model(
      InputMediaPhoto,
      [
        {:type, [:string]},
        {:media, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:has_spoiler, [:boolean], :optional}
      ],
      "Represents a photo to be sent."
    )

    model(
      InputMediaVideo,
      [
        {:type, [:string]},
        {:media, [:string]},
        {:thumbnail, [:file, :string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:width, [:integer], :optional},
        {:height, [:integer], :optional},
        {:duration, [:integer], :optional},
        {:supports_streaming, [:boolean], :optional},
        {:has_spoiler, [:boolean], :optional}
      ],
      "Represents a video to be sent."
    )

    model(
      InputMediaAnimation,
      [
        {:type, [:string]},
        {:media, [:string]},
        {:thumbnail, [:file, :string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:width, [:integer], :optional},
        {:height, [:integer], :optional},
        {:duration, [:integer], :optional},
        {:has_spoiler, [:boolean], :optional}
      ],
      "Represents an animation file (GIF or H.264/MPEG-4 AVC video without sound) to be sent."
    )

    model(
      InputMediaAudio,
      [
        {:type, [:string]},
        {:media, [:string]},
        {:thumbnail, [:file, :string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:duration, [:integer], :optional},
        {:performer, [:string], :optional},
        {:title, [:string], :optional}
      ],
      "Represents an audio file to be treated as music to be sent."
    )

    model(
      InputMediaDocument,
      [
        {:type, [:string]},
        {:media, [:string]},
        {:thumbnail, [:file, :string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:disable_content_type_detection, [:boolean], :optional}
      ],
      "Represents a general file to be sent."
    )

    model(
      Sticker,
      [
        {:file_id, [:string]},
        {:file_unique_id, [:string]},
        {:type, [:string]},
        {:width, [:integer]},
        {:height, [:integer]},
        {:is_animated, [:boolean]},
        {:is_video, [:boolean]},
        {:thumbnail, [PhotoSize], :optional},
        {:emoji, [:string], :optional},
        {:set_name, [:string], :optional},
        {:premium_animation, [File], :optional},
        {:mask_position, [MaskPosition], :optional},
        {:custom_emoji_id, [:string], :optional},
        {:needs_repainting, [:boolean], :optional},
        {:file_size, [:integer], :optional}
      ],
      "This object represents a sticker."
    )

    model(
      StickerSet,
      [
        {:name, [:string]},
        {:title, [:string]},
        {:sticker_type, [:string]},
        {:is_animated, [:boolean]},
        {:is_video, [:boolean]},
        {:stickers, [{:array, Sticker}]},
        {:thumbnail, [PhotoSize], :optional}
      ],
      "This object represents a sticker set."
    )

    model(
      MaskPosition,
      [{:point, [:string]}, {:x_shift, [:float]}, {:y_shift, [:float]}, {:scale, [:float]}],
      "This object describes the position on faces where a mask should be placed by default."
    )

    model(
      InputSticker,
      [
        {:sticker, [:file, :string]},
        {:emoji_list, [{:array, :string}]},
        {:mask_position, [MaskPosition], :optional},
        {:keywords, [{:array, :string}], :optional}
      ],
      "This object describes a sticker to be added to a sticker set."
    )

    model(
      InlineQuery,
      [
        {:id, [:string]},
        {:from, [User]},
        {:query, [:string]},
        {:offset, [:string]},
        {:chat_type, [:string], :optional},
        {:location, [Location], :optional}
      ],
      "This object represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results."
    )

    model(
      InlineQueryResultsButton,
      [{:text, [:string]}, {:web_app, [WebAppInfo], :optional}, {:start_parameter, [:string], :optional}],
      "This object represents a button to be shown above inline query results. You must use exactly one of the optional fields."
    )

    model(
      InlineQueryResultArticle,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:title, [:string]},
        {:input_message_content, [InputMessageContent]},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:url, [:string], :optional},
        {:hide_url, [:boolean], :optional},
        {:description, [:string], :optional},
        {:thumbnail_url, [:string], :optional},
        {:thumbnail_width, [:integer], :optional},
        {:thumbnail_height, [:integer], :optional}
      ],
      "Represents a link to an article or web page."
    )

    model(
      InlineQueryResultPhoto,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:photo_url, [:string]},
        {:thumbnail_url, [:string]},
        {:photo_width, [:integer], :optional},
        {:photo_height, [:integer], :optional},
        {:title, [:string], :optional},
        {:description, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a photo. By default, this photo will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo."
    )

    model(
      InlineQueryResultGif,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:gif_url, [:string]},
        {:gif_width, [:integer], :optional},
        {:gif_height, [:integer], :optional},
        {:gif_duration, [:integer], :optional},
        {:thumbnail_url, [:string]},
        {:thumbnail_mime_type, [:string], :optional},
        {:title, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to an animated GIF file. By default, this animated GIF file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultMpeg4Gif,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:mpeg4_url, [:string]},
        {:mpeg4_width, [:integer], :optional},
        {:mpeg4_height, [:integer], :optional},
        {:mpeg4_duration, [:integer], :optional},
        {:thumbnail_url, [:string]},
        {:thumbnail_mime_type, [:string], :optional},
        {:title, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a video animation (H.264/MPEG-4 AVC video without sound). By default, this animated MPEG-4 file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultVideo,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:video_url, [:string]},
        {:mime_type, [:string]},
        {:thumbnail_url, [:string]},
        {:title, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:video_width, [:integer], :optional},
        {:video_height, [:integer], :optional},
        {:video_duration, [:integer], :optional},
        {:description, [:string], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a page containing an embedded video player or a video file. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video."
    )

    model(
      InlineQueryResultAudio,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:audio_url, [:string]},
        {:title, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:performer, [:string], :optional},
        {:audio_duration, [:integer], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to an MP3 audio file. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio."
    )

    model(
      InlineQueryResultVoice,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:voice_url, [:string]},
        {:title, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:voice_duration, [:integer], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a voice recording in an .OGG container encoded with OPUS. By default, this voice recording will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the the voice message."
    )

    model(
      InlineQueryResultDocument,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:title, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:document_url, [:string]},
        {:mime_type, [:string]},
        {:description, [:string], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional},
        {:thumbnail_url, [:string], :optional},
        {:thumbnail_width, [:integer], :optional},
        {:thumbnail_height, [:integer], :optional}
      ],
      "Represents a link to a file. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file. Currently, only .PDF and .ZIP files can be sent using this method."
    )

    model(
      InlineQueryResultLocation,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:latitude, [:float]},
        {:longitude, [:float]},
        {:title, [:string]},
        {:horizontal_accuracy, [:float], :optional},
        {:live_period, [:integer], :optional},
        {:heading, [:integer], :optional},
        {:proximity_alert_radius, [:integer], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional},
        {:thumbnail_url, [:string], :optional},
        {:thumbnail_width, [:integer], :optional},
        {:thumbnail_height, [:integer], :optional}
      ],
      "Represents a location on a map. By default, the location will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the location."
    )

    model(
      InlineQueryResultVenue,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:latitude, [:float]},
        {:longitude, [:float]},
        {:title, [:string]},
        {:address, [:string]},
        {:foursquare_id, [:string], :optional},
        {:foursquare_type, [:string], :optional},
        {:google_place_id, [:string], :optional},
        {:google_place_type, [:string], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional},
        {:thumbnail_url, [:string], :optional},
        {:thumbnail_width, [:integer], :optional},
        {:thumbnail_height, [:integer], :optional}
      ],
      "Represents a venue. By default, the venue will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the venue."
    )

    model(
      InlineQueryResultContact,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:phone_number, [:string]},
        {:first_name, [:string]},
        {:last_name, [:string], :optional},
        {:vcard, [:string], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional},
        {:thumbnail_url, [:string], :optional},
        {:thumbnail_width, [:integer], :optional},
        {:thumbnail_height, [:integer], :optional}
      ],
      "Represents a contact with a phone number. By default, this contact will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the contact."
    )

    model(
      InlineQueryResultGame,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:game_short_name, [:string]},
        {:reply_markup, [InlineKeyboardMarkup], :optional}
      ],
      "Represents a Game."
    )

    model(
      InlineQueryResultCachedPhoto,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:photo_file_id, [:string]},
        {:title, [:string], :optional},
        {:description, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a photo stored on the Telegram servers. By default, this photo will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo."
    )

    model(
      InlineQueryResultCachedGif,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:gif_file_id, [:string]},
        {:title, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to an animated GIF file stored on the Telegram servers. By default, this animated GIF file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with specified content instead of the animation."
    )

    model(
      InlineQueryResultCachedMpeg4Gif,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:mpeg4_file_id, [:string]},
        {:title, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers. By default, this animated MPEG-4 file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation."
    )

    model(
      InlineQueryResultCachedSticker,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:sticker_file_id, [:string]},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a sticker stored on the Telegram servers. By default, this sticker will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the sticker."
    )

    model(
      InlineQueryResultCachedDocument,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:title, [:string]},
        {:document_file_id, [:string]},
        {:description, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a file stored on the Telegram servers. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file."
    )

    model(
      InlineQueryResultCachedVideo,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:video_file_id, [:string]},
        {:title, [:string]},
        {:description, [:string], :optional},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a video file stored on the Telegram servers. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video."
    )

    model(
      InlineQueryResultCachedVoice,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:voice_file_id, [:string]},
        {:title, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to a voice message stored on the Telegram servers. By default, this voice message will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the voice message."
    )

    model(
      InlineQueryResultCachedAudio,
      [
        {:type, [:string]},
        {:id, [:string]},
        {:audio_file_id, [:string]},
        {:caption, [:string], :optional},
        {:parse_mode, [:string], :optional},
        {:caption_entities, [{:array, MessageEntity}], :optional},
        {:reply_markup, [InlineKeyboardMarkup], :optional},
        {:input_message_content, [InputMessageContent], :optional}
      ],
      "Represents a link to an MP3 audio file stored on the Telegram servers. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio."
    )

    model(
      InputTextMessageContent,
      [
        {:message_text, [:string]},
        {:parse_mode, [:string], :optional},
        {:entities, [{:array, MessageEntity}], :optional},
        {:link_preview_options, [LinkPreviewOptions], :optional}
      ],
      "Represents the content of a text message to be sent as the result of an inline query."
    )

    model(
      InputLocationMessageContent,
      [
        {:latitude, [:float]},
        {:longitude, [:float]},
        {:horizontal_accuracy, [:float], :optional},
        {:live_period, [:integer], :optional},
        {:heading, [:integer], :optional},
        {:proximity_alert_radius, [:integer], :optional}
      ],
      "Represents the content of a location message to be sent as the result of an inline query."
    )

    model(
      InputVenueMessageContent,
      [
        {:latitude, [:float]},
        {:longitude, [:float]},
        {:title, [:string]},
        {:address, [:string]},
        {:foursquare_id, [:string], :optional},
        {:foursquare_type, [:string], :optional},
        {:google_place_id, [:string], :optional},
        {:google_place_type, [:string], :optional}
      ],
      "Represents the content of a venue message to be sent as the result of an inline query."
    )

    model(
      InputContactMessageContent,
      [
        {:phone_number, [:string]},
        {:first_name, [:string]},
        {:last_name, [:string], :optional},
        {:vcard, [:string], :optional}
      ],
      "Represents the content of a contact message to be sent as the result of an inline query."
    )

    model(
      InputInvoiceMessageContent,
      [
        {:title, [:string]},
        {:description, [:string]},
        {:payload, [:string]},
        {:provider_token, [:string]},
        {:currency, [:string]},
        {:prices, [{:array, LabeledPrice}]},
        {:max_tip_amount, [:integer], :optional},
        {:suggested_tip_amounts, [{:array, :integer}], :optional},
        {:provider_data, [:string], :optional},
        {:photo_url, [:string], :optional},
        {:photo_size, [:integer], :optional},
        {:photo_width, [:integer], :optional},
        {:photo_height, [:integer], :optional},
        {:need_name, [:boolean], :optional},
        {:need_phone_number, [:boolean], :optional},
        {:need_email, [:boolean], :optional},
        {:need_shipping_address, [:boolean], :optional},
        {:send_phone_number_to_provider, [:boolean], :optional},
        {:send_email_to_provider, [:boolean], :optional},
        {:is_flexible, [:boolean], :optional}
      ],
      "Represents the content of an invoice message to be sent as the result of an inline query."
    )

    model(
      ChosenInlineResult,
      [
        {:result_id, [:string]},
        {:from, [User]},
        {:location, [Location], :optional},
        {:inline_message_id, [:string], :optional},
        {:query, [:string]}
      ],
      "Represents a result of an inline query that was chosen by the user and sent to their chat partner."
    )

    model(
      SentWebAppMessage,
      [{:inline_message_id, [:string], :optional}],
      "Describes an inline message sent by a Web App on behalf of a user."
    )

    model(
      LabeledPrice,
      [{:label, [:string]}, {:amount, [:integer]}],
      "This object represents a portion of the price for goods or services."
    )

    model(
      Invoice,
      [
        {:title, [:string]},
        {:description, [:string]},
        {:start_parameter, [:string]},
        {:currency, [:string]},
        {:total_amount, [:integer]}
      ],
      "This object contains basic information about an invoice."
    )

    model(
      ShippingAddress,
      [
        {:country_code, [:string]},
        {:state, [:string]},
        {:city, [:string]},
        {:street_line1, [:string]},
        {:street_line2, [:string]},
        {:post_code, [:string]}
      ],
      "This object represents a shipping address."
    )

    model(
      OrderInfo,
      [
        {:name, [:string], :optional},
        {:phone_number, [:string], :optional},
        {:email, [:string], :optional},
        {:shipping_address, [ShippingAddress], :optional}
      ],
      "This object represents information about an order."
    )

    model(
      ShippingOption,
      [{:id, [:string]}, {:title, [:string]}, {:prices, [{:array, LabeledPrice}]}],
      "This object represents one shipping option."
    )

    model(
      SuccessfulPayment,
      [
        {:currency, [:string]},
        {:total_amount, [:integer]},
        {:invoice_payload, [:string]},
        {:shipping_option_id, [:string], :optional},
        {:order_info, [OrderInfo], :optional},
        {:telegram_payment_charge_id, [:string]},
        {:provider_payment_charge_id, [:string]}
      ],
      "This object contains basic information about a successful payment."
    )

    model(
      ShippingQuery,
      [{:id, [:string]}, {:from, [User]}, {:invoice_payload, [:string]}, {:shipping_address, [ShippingAddress]}],
      "This object contains information about an incoming shipping query."
    )

    model(
      PreCheckoutQuery,
      [
        {:id, [:string]},
        {:from, [User]},
        {:currency, [:string]},
        {:total_amount, [:integer]},
        {:invoice_payload, [:string]},
        {:shipping_option_id, [:string], :optional},
        {:order_info, [OrderInfo], :optional}
      ],
      "This object contains information about an incoming pre-checkout query."
    )

    model(
      PassportData,
      [{:data, [{:array, EncryptedPassportElement}]}, {:credentials, [EncryptedCredentials]}],
      "Describes Telegram Passport data shared with the bot by the user."
    )

    model(
      PassportFile,
      [{:file_id, [:string]}, {:file_unique_id, [:string]}, {:file_size, [:integer]}, {:file_date, [:integer]}],
      "This object represents a file uploaded to Telegram Passport. Currently all Telegram Passport files are in JPEG format when decrypted and don't exceed 10MB."
    )

    model(
      EncryptedPassportElement,
      [
        {:type, [:string]},
        {:data, [:string], :optional},
        {:phone_number, [:string], :optional},
        {:email, [:string], :optional},
        {:files, [{:array, PassportFile}], :optional},
        {:front_side, [PassportFile], :optional},
        {:reverse_side, [PassportFile], :optional},
        {:selfie, [PassportFile], :optional},
        {:translation, [{:array, PassportFile}], :optional},
        {:hash, [:string]}
      ],
      "Describes documents or other Telegram Passport elements shared with the bot by the user."
    )

    model(
      EncryptedCredentials,
      [{:data, [:string]}, {:hash, [:string]}, {:secret, [:string]}],
      "Describes data required for decrypting and authenticating EncryptedPassportElement. See the Telegram Passport Documentation for a complete description of the data decryption and authentication processes."
    )

    model(
      PassportElementErrorDataField,
      [
        {:source, [:string]},
        {:type, [:string]},
        {:field_name, [:string]},
        {:data_hash, [:string]},
        {:message, [:string]}
      ],
      "Represents an issue in one of the data fields that was provided by the user. The error is considered resolved when the field's value changes."
    )

    model(
      PassportElementErrorFrontSide,
      [{:source, [:string]}, {:type, [:string]}, {:file_hash, [:string]}, {:message, [:string]}],
      "Represents an issue with the front side of a document. The error is considered resolved when the file with the front side of the document changes."
    )

    model(
      PassportElementErrorReverseSide,
      [{:source, [:string]}, {:type, [:string]}, {:file_hash, [:string]}, {:message, [:string]}],
      "Represents an issue with the reverse side of a document. The error is considered resolved when the file with reverse side of the document changes."
    )

    model(
      PassportElementErrorSelfie,
      [{:source, [:string]}, {:type, [:string]}, {:file_hash, [:string]}, {:message, [:string]}],
      "Represents an issue with the selfie with a document. The error is considered resolved when the file with the selfie changes."
    )

    model(
      PassportElementErrorFile,
      [{:source, [:string]}, {:type, [:string]}, {:file_hash, [:string]}, {:message, [:string]}],
      "Represents an issue with a document scan. The error is considered resolved when the file with the document scan changes."
    )

    model(
      PassportElementErrorFiles,
      [{:source, [:string]}, {:type, [:string]}, {:file_hashes, [{:array, :string}]}, {:message, [:string]}],
      "Represents an issue with a list of scans. The error is considered resolved when the list of files containing the scans changes."
    )

    model(
      PassportElementErrorTranslationFile,
      [{:source, [:string]}, {:type, [:string]}, {:file_hash, [:string]}, {:message, [:string]}],
      "Represents an issue with one of the files that constitute the translation of a document. The error is considered resolved when the file changes."
    )

    model(
      PassportElementErrorTranslationFiles,
      [{:source, [:string]}, {:type, [:string]}, {:file_hashes, [{:array, :string}]}, {:message, [:string]}],
      "Represents an issue with the translated version of a document. The error is considered resolved when a file with the document translation change."
    )

    model(
      PassportElementErrorUnspecified,
      [{:source, [:string]}, {:type, [:string]}, {:element_hash, [:string]}, {:message, [:string]}],
      "Represents an issue in an unspecified place. The error is considered resolved when new data is added."
    )

    model(
      Game,
      [
        {:title, [:string]},
        {:description, [:string]},
        {:photo, [{:array, PhotoSize}]},
        {:text, [:string], :optional},
        {:text_entities, [{:array, MessageEntity}], :optional},
        {:animation, [Animation], :optional}
      ],
      "This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers."
    )

    model(
      CallbackGame,
      [
        {:user_id, [:integer]},
        {:score, [:integer]},
        {:force, [:boolean], :optional},
        {:disable_edit_message, [:boolean], :optional},
        {:chat_id, [:integer], :optional},
        {:message_id, [:integer], :optional},
        {:inline_message_id, [:string], :optional}
      ],
      "A placeholder, currently holds no information. Use BotFather to set up your game."
    )

    model(
      GameHighScore,
      [{:position, [:integer]}, {:user, [User]}, {:score, [:integer]}],
      "This object represents one row of the high scores table for a game."
    )

    # 173 models

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

      defstruct []

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

      defstruct []

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

    defmodule MenuButton do
      @moduledoc """
      MenuButton model. Valid subtypes: MenuButtonCommands, MenuButtonWebApp, MenuButtonDefault
      """
      @type t :: MenuButtonCommands.t() | MenuButtonWebApp.t() | MenuButtonDefault.t()

      defstruct []

      def decode_as, do: %{}

      def subtypes do
        [MenuButtonCommands, MenuButtonWebApp, MenuButtonDefault]
      end
    end

    defmodule InputMedia do
      @moduledoc """
      InputMedia model. Valid subtypes: InputMediaAnimation, InputMediaDocument, InputMediaAudio, InputMediaPhoto, InputMediaVideo
      """
      @type t ::
              InputMediaAnimation.t()
              | InputMediaDocument.t()
              | InputMediaAudio.t()
              | InputMediaPhoto.t()
              | InputMediaVideo.t()

      defstruct []

      def decode_as, do: %{}

      def subtypes do
        [InputMediaAnimation, InputMediaDocument, InputMediaAudio, InputMediaPhoto, InputMediaVideo]
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

      defstruct []

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

      defstruct []

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

      defstruct []

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

    # 7 generics
  end

  # END AUTO GENERATED
end
