defmodule Telex.Model do
  @moduledoc """
  Types used in Telegram Bot API.

  ## Reference
  https://core.telegram.org/bots/api#available-types
  """

  import Telex.Macros

  # AUTO GENERATED

  model Update, [{:update_id, :integer}, {:message, Message}, {:edited_message, Message}, {:channel_post, Message}, {:edited_channel_post, Message}, {:inline_query, InlineQuery}, {:chosen_inline_result, ChosenInlineResult}, {:callback_query, CallbackQuery}]

  model WebhookInfo, [{:url, :string}, {:has_custom_certificate, :boolean}, {:pending_update_count, :integer}, {:last_error_date, :integer}, {:last_error_message, :string}, {:max_connections, :integer}, {:allowed_updates, {:array, :string}}]

  model User, [{:id, :integer}, {:first_name, :string}, {:last_name, :string}, {:username, :string}]

  model Chat, [{:id, :integer}, {:type, :string}, {:title, :string}, {:username, :string}, {:first_name, :string}, {:last_name, :string}, {:all_members_are_administrators, :boolean}]

  model Message, [{:message_id, :integer}, {:from, User}, {:date, :integer}, {:chat, Chat}, {:forward_from, User}, {:forward_from_chat, Chat}, {:forward_from_message_id, :integer}, {:forward_date, :integer}, {:reply_to_message, Message}, {:edit_date, :integer}, {:text, :string}, {:entities, {:array, MessageEntity}}, {:audio, Audio}, {:document, Document}, {:game, Game}, {:photo, {:array, PhotoSize}}, {:sticker, Sticker}, {:video, Video}, {:voice, Voice}, {:caption, :string}, {:contact, Contact}, {:location, Location}, {:venue, Venue}, {:new_chat_member, User}, {:left_chat_member, User}, {:new_chat_title, :string}, {:new_chat_photo, {:array, PhotoSize}}, {:delete_chat_photo, True}, {:group_chat_created, True}, {:supergroup_chat_created, True}, {:channel_chat_created, True}, {:migrate_to_chat_id, :integer}, {:migrate_from_chat_id, :integer}, {:pinned_message, Message}]

  model MessageEntity, [{:type, :string}, {:offset, :integer}, {:length, :integer}, {:url, :string}, {:user, User}]

  model PhotoSize, [{:file_id, :string}, {:width, :integer}, {:height, :integer}, {:file_size, :integer}]

  model Audio, [{:file_id, :string}, {:duration, :integer}, {:performer, :string}, {:title, :string}, {:mime_type, :string}, {:file_size, :integer}]

  model Document, [{:file_id, :string}, {:thumb, PhotoSize}, {:file_name, :string}, {:mime_type, :string}, {:file_size, :integer}]

  model Sticker, [{:file_id, :string}, {:width, :integer}, {:height, :integer}, {:thumb, PhotoSize}, {:emoji, :string}, {:file_size, :integer}]

  model Video, [{:file_id, :string}, {:width, :integer}, {:height, :integer}, {:duration, :integer}, {:thumb, PhotoSize}, {:mime_type, :string}, {:file_size, :integer}]

  model Voice, [{:file_id, :string}, {:duration, :integer}, {:mime_type, :string}, {:file_size, :integer}]

  model Contact, [{:phone_number, :string}, {:first_name, :string}, {:last_name, :string}, {:user_id, :integer}]

  model Location, [{:longitude, Float}, {:latitude, Float}]

  model Venue, [{:location, Location}, {:title, :string}, {:address, :string}, {:foursquare_id, :string}]

  model UserProfilePhotos, [{:total_count, :integer}, {:photos, {:array, PhotoSize}}]

  model File, [{:file_id, :string}, {:file_size, :integer}, {:file_path, :string}]

  model ReplyKeyboardMarkup, [{:keyboard, {:array, KeyboardButton}}, {:resize_keyboard, :boolean}, {:one_time_keyboard, :boolean}, {:selective, :boolean}]

  model KeyboardButton, [{:text, :string}, {:request_contact, :boolean}, {:request_location, :boolean}]

  model ReplyKeyboardRemove, [{:remove_keyboard, True}, {:selective, :boolean}]

  model InlineKeyboardMarkup, [{:inline_keyboard, {:array, InlineKeyboardButton}}]

  model InlineKeyboardButton, [{:text, :string}, {:url, :string}, {:callback_data, :string}, {:switch_inline_query, :string}, {:switch_inline_query_current_chat, :string}, {:callback_game, CallbackGame}]

  model CallbackQuery, [{:id, :string}, {:from, User}, {:message, Message}, {:inline_message_id, :string}, {:chat_instance, :string}, {:data, :string}, {:game_short_name, :string}]

  model ForceReply, [{:force_reply, True}, {:selective, :boolean}]

  model ChatMember, [{:user, User}, {:status, :string}]

  model ResponseParameters, [{:migrate_to_chat_id, :integer}, {:retry_after, :integer}]

  model InputFile, [{:chat_id, :integer}, {:text, :string}, {:parse_mode, :string, :optional}, {:disable_web_page_preview, :boolean, :optional}, {:disable_notification, :boolean, :optional}, {:reply_to_message_id, :integer, :optional}, {:reply_markup, InlineKeyboardMarkup, :optional}]

  model InlineQuery, [{:id, :string}, {:from, User}, {:location, Location}, {:query, :string}, {:offset, :string}]

  model InlineQueryResult, [{:type, :string}, {:id, :string}, {:title, :string}, {:input_message_content, InputMessageContent}, {:reply_markup, InlineKeyboardMarkup}, {:url, :string}, {:hide_url, :boolean}, {:description, :string}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultArticle, [{:type, :string}, {:id, :string}, {:title, :string}, {:input_message_content, InputMessageContent}, {:reply_markup, InlineKeyboardMarkup}, {:url, :string}, {:hide_url, :boolean}, {:description, :string}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultPhoto, [{:type, :string}, {:id, :string}, {:photo_url, :string}, {:thumb_url, :string}, {:photo_width, :integer}, {:photo_height, :integer}, {:title, :string}, {:description, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultGif, [{:type, :string}, {:id, :string}, {:gif_url, :string}, {:gif_width, :integer}, {:gif_height, :integer}, {:thumb_url, :string}, {:title, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultMpeg4Gif, [{:type, :string}, {:id, :string}, {:mpeg4_url, :string}, {:mpeg4_width, :integer}, {:mpeg4_height, :integer}, {:thumb_url, :string}, {:title, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultVideo, [{:type, :string}, {:id, :string}, {:video_url, :string}, {:mime_type, :string}, {:thumb_url, :string}, {:title, :string}, {:caption, :string}, {:video_width, :integer}, {:video_height, :integer}, {:video_duration, :integer}, {:description, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultAudio, [{:type, :string}, {:id, :string}, {:audio_url, :string}, {:title, :string}, {:caption, :string}, {:performer, :string}, {:audio_duration, :integer}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultVoice, [{:type, :string}, {:id, :string}, {:voice_url, :string}, {:title, :string}, {:caption, :string}, {:voice_duration, :integer}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultDocument, [{:type, :string}, {:id, :string}, {:title, :string}, {:caption, :string}, {:document_url, :string}, {:mime_type, :string}, {:description, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultLocation, [{:type, :string}, {:id, :string}, {:latitude, :float}, {:longitude, :float}, {:title, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultVenue, [{:type, :string}, {:id, :string}, {:latitude, Float}, {:longitude, Float}, {:title, :string}, {:address, :string}, {:foursquare_id, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultContact, [{:type, :string}, {:id, :string}, {:phone_number, :string}, {:first_name, :string}, {:last_name, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}, {:thumb_url, :string}, {:thumb_width, :integer}, {:thumb_height, :integer}]

  model InlineQueryResultGame, [{:type, :string}, {:id, :string}, {:game_short_name, :string}, {:reply_markup, InlineKeyboardMarkup}]

  model InlineQueryResultCachedPhoto, [{:type, :string}, {:id, :string}, {:photo_file_id, :string}, {:title, :string}, {:description, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedGif, [{:type, :string}, {:id, :string}, {:gif_file_id, :string}, {:title, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedMpeg4Gif, [{:type, :string}, {:id, :string}, {:mpeg4_file_id, :string}, {:title, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedSticker, [{:type, :string}, {:id, :string}, {:sticker_file_id, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedDocument, [{:type, :string}, {:id, :string}, {:title, :string}, {:document_file_id, :string}, {:description, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedVideo, [{:type, :string}, {:id, :string}, {:video_file_id, :string}, {:title, :string}, {:description, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedVoice, [{:type, :string}, {:id, :string}, {:voice_file_id, :string}, {:title, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InlineQueryResultCachedAudio, [{:type, :string}, {:id, :string}, {:audio_file_id, :string}, {:caption, :string}, {:reply_markup, InlineKeyboardMarkup}, {:input_message_content, InputMessageContent}]

  model InputMessageContent, [{:message_text, :string}, {:parse_mode, :string}, {:disable_web_page_preview, :boolean}]

  model InputTextMessageContent, [{:message_text, :string}, {:parse_mode, :string}, {:disable_web_page_preview, :boolean}]

  model InputLocationMessageContent, [{:latitude, Float}, {:longitude, Float}]

  model InputVenueMessageContent, [{:latitude, Float}, {:longitude, Float}, {:title, :string}, {:address, :string}, {:foursquare_id, :string}]

  model InputContactMessageContent, [{:phone_number, :string}, {:first_name, :string}, {:last_name, :string}]

  model ChosenInlineResult, [{:result_id, :string}, {:from, User}, {:location, Location}, {:inline_message_id, :string}, {:query, :string}]

  model Game, [{:title, :string}, {:description, :string}, {:photo, {:array, PhotoSize}}, {:text, :string}, {:text_entities, {:array, MessageEntity}}, {:animation, Animation}]

  model Animation, [{:file_id, :string}, {:thumb, PhotoSize}, {:file_name, :string}, {:mime_type, :string}, {:file_size, :integer}]

  model CallbackGame, [{:user_id, :integer}, {:score, :integer}, {:force, :boolean, :optional}, {:disable_edit_message, :boolean, :optional}, {:chat_id, :integer, :optional}, {:message_id, :integer, :optional}, {:inline_message_id, :string, :optional}]

  model GameHighScore, [{:position, :integer}, {:user, User}, {:score, :integer}]

end
