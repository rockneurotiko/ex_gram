defmodule ExGram.Dsl do
  @moduledoc """
  Mini DSL to build answers based on the context (`ExGram.Cnt`) easily.

  This module is automatically imported when using `ExGram.Bot`. Functions in this
  module allow you to build responses declaratively by chaining operations on the
  context. The responses are queued and executed after your handler returns.

  See the [Sending Messages](sending-messages.md) guide for detailed usage examples.
  """

  alias ExGram.Cnt
  alias ExGram.Model.Chat
  alias ExGram.Model.InlineKeyboardMarkup
  alias ExGram.Model.InlineQueryResult
  alias ExGram.Model.Message
  alias ExGram.Model.ReplyKeyboardMarkup
  alias ExGram.Model.Update
  alias ExGram.Responses
  alias ExGram.Responses.Answer
  alias ExGram.Responses.AnswerCallback
  alias ExGram.Responses.AnswerInlineQuery
  alias ExGram.Responses.DeleteMessage
  alias ExGram.Responses.EditInline
  alias ExGram.Responses.EditMarkup
  alias ExGram.Responses.SendDocument

  require Logger

  @spec answer(Cnt.t(), String.t()) :: Cnt.t()
  @spec answer(Cnt.t(), String.t(), keyword()) :: Cnt.t()
  
  
  @doc """
Queues an Answer response containing the given text and options on the provided context.

## Parameters

  - text: The text to send in the answer.
  - ops: Keyword list of response options (for example `:parse_mode`, `:reply_markup`, etc.).

## Returns

  - The updated `Cnt` with the queued Answer response.
"""
@spec answer(Cnt.t(), Message.t(), String.t()) :: Cnt.t()
@spec answer(Cnt.t(), Message.t(), String.t(), keyword()) :: Cnt.t()
def answer(cnt, text, ops \\ [])

  @doc """
  Queues a text response for the given context.
  
  Creates an Answer response using the provided text and options, and adds it to the context's pending responses.
  
  ## Parameters
  
    - text: Message text to send.
    - ops: Keyword list of response options (for example keyboard, parse_mode, etc.).
  
  """
  @spec answer(Cnt.t(), String.t(), keyword()) :: Cnt.t()
  def answer(cnt, text, ops) when is_binary(text) and is_list(ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> add_answer(cnt)
  end

  def answer(cnt, m, text) when is_map(m) and is_binary(text), do: answer(cnt, m, text, [])

  @doc """
  Queues an Answer response with the given text and options attached to the provided message.
  
  ## Parameters
  
    - m: Message to associate the answer with.
    - ops: Keyword list of options applied to the answer (for example: `parse_mode`, `reply_markup`).
  """
  @spec answer(ExGram.Cnt.t(), ExGram.Model.Message.t(), String.t(), keyword()) :: ExGram.Cnt.t()
  def answer(cnt, m, text, ops) do
    Answer |> Responses.new(%{text: text, ops: ops}) |> Responses.set_msg(m) |> add_answer(cnt)
  end

  
  
  @doc """
  Queues an AnswerCallback response for the given message.
  
  ## Parameters
  
    - msg: The Message struct that contains the callback query to answer.
    - ops: Keyword list of options for the callback answer (for example `:text` or `:show_alert`).
  
  """
  @spec answer_callback(Cnt.t(), Message.t()) :: Cnt.t()
  @spec answer_callback(Cnt.t(), Message.t(), keyword()) :: Cnt.t()
  def answer_callback(cnt, msg, ops \\ []) do
    AnswerCallback |> Responses.new(%{ops: ops}) |> Responses.set_msg(msg) |> add_answer(cnt)
  end

  
  
  @doc """
  Queues an inline query response containing the given articles and options.
  
  - articles: list of `InlineQueryResult.t()` structs to include in the inline query response.
  - ops: optional keyword list of response options (e.g., caching and pagination-related fields) to attach to the response.
  
  """
  @spec answer_inline_query(Cnt.t(), [InlineQueryResult.t()]) :: Cnt.t()
  @spec answer_inline_query(Cnt.t(), [InlineQueryResult.t()], keyword()) :: Cnt.t()
  def answer_inline_query(cnt, articles, ops \\ []) do
    AnswerInlineQuery |> Responses.new(%{articles: articles, ops: ops}) |> add_answer(cnt)
  end

  # /3
  @doc """
Creates an inline edit response with the given text and queues it on the provided context.

Returns the updated context with an EditInline response appended to its answers.
"""
@spec edit(Cnt.t(), :inline, String.t()) :: Cnt.t()
  def edit(cnt, :inline, text) when is_binary(text), do: edit(cnt, :inline, text, [])

  @doc """
  Queues an EditMarkup response built from the given markup options onto the provided context.
  
  ## Parameters
  
    - cnt: The ExGram.Cnt context to which the response will be added.
    - ops: Keyword list of markup options (e.g., keyboard or reply markup fields).
  
  ## Returns
  
    - The updated `Cnt.t()` with the `EditMarkup` response appended.
  """
  @spec edit(Cnt.t(), :markup, keyword()) :: Cnt.t()
  def edit(cnt, :markup, ops) when is_list(ops) do
    EditMarkup |> Responses.new(%{ops: ops}) |> add_answer(cnt)
  end

  # /4
  @doc """
  Queues an inline edit response with the given text and options.
  
  The provided `text` will be used as the new inline content; `ops` may include editing options (e.g., parse mode, reply markup) and will be attached to the queued EditInline response.
  """
  @spec edit(Cnt.t(), :inline, String.t(), keyword()) :: Cnt.t()
  def edit(cnt, :inline, text, ops) when is_binary(text) do
    EditInline |> Responses.new(%{text: text, ops: ops}) |> add_answer(cnt)
  end

  @doc """
  Queues an EditMarkup response for the given message using the provided markup options.
  
  Parameters
  
    - cnt: The context to receive the queued response.
    - m: The message to be edited.
    - ops: Keyword list of markup options to apply to the message.
  
  """
  @spec edit(Cnt.t(), :markup, Message.t(), keyword()) :: Cnt.t()
  def edit(cnt, :markup, m, ops) do
    EditMarkup |> Responses.new(%{ops: ops}) |> Responses.set_msg(m) |> add_answer(cnt)
  end

  # /5
  @doc """
  Queue an inline edit that replaces the text of a specific message.
  
  ## Parameters
  
    - cnt: Current context accumulator.
    - m: Target Message to edit.
    - text: New text to set on the message.
    - ops: Keyword list of edit options (e.g., parse mode, disable_web_page_preview).
  
  ## Returns
  
    - Updated `Cnt.t()` with the edit response appended.
  """
  @spec edit(Cnt.t(), :inline, Message.t(), String.t(), keyword()) :: Cnt.t()
  def edit(cnt, :inline, m, text, ops) do
    EditInline
    |> Responses.new(%{text: text, ops: ops})
    |> Responses.set_msg(m)
    |> add_answer(cnt)
  end

  @doc """
  Queues a markup edit for the given message using the provided options.
  
  The string parameter is ignored; `ops` is used to build the markup edit targeting `m`.
  """
  @spec edit(Cnt.t(), :markup, Message.t(), String.t(), keyword()) :: Cnt.t()
  def edit(cnt, :markup, m, _, ops) do
    edit(cnt, :markup, m, ops)
  end

  @doc """
Raises a RuntimeError for unsupported parameter combinations passed to edit/5.

This clause is the catch-all fallback and raises a RuntimeError with the message "Wrong params" when the provided arguments do not match any valid edit/5 function clause.
"""
@spec edit(Cnt.t(), any(), any(), any(), any()) :: no_return()
def edit(_cnt, _, _, _, _), do: raise("Wrong params")

  @doc """
  Queue deletion of the message inferred from the current update in the given context.
  
  If no message can be inferred from the context, the context is returned unchanged.
  """
  @spec delete(Cnt.t()) :: Cnt.t()
  def delete(cnt) do
    delete(cnt, extract_msg(cnt))
  end

  @doc """
No-op when the message is `nil`.

If no message is provided (`nil`), the context is returned unchanged.

## Parameters

  - cnt: The ExGram.Cnt context.
  - _message_: The message to delete, or `nil` to indicate no message.

## Returns

  - The unchanged `cnt`.
"""
@spec delete(Cnt.t(), Message.t() | nil) :: Cnt.t()
  def delete(cnt, nil), do: cnt

  @doc """
  Queues a DeleteMessage response targeting the given message.
  
  This clause delegates to the three-argument `delete/3` with an empty options list.
  """
  @spec delete(Cnt.t(), any()) :: Cnt.t()
  def delete(cnt, msg) do
    delete(cnt, msg, [])
  end

  @doc """
  Queues a DeleteMessage response targeting the given message.
  
  ## Parameters
  
    - msg: The message to be deleted.
    - ops: Optional keyword list of additional send options (e.g., target chat, reply markup).
  
  Returns the updated `Cnt.t()` with the DeleteMessage response appended to its answers queue.
  """
  @spec delete(Cnt.t(), Message.t(), keyword()) :: Cnt.t()
  def delete(cnt, msg, ops) do
    DeleteMessage |> Responses.new(%{ops: ops}) |> Responses.set_msg(msg) |> add_answer(cnt)
  end

  @doc """
  Registers a callback to run after a response is produced.
  
  The provided function is invoked with two arguments: the last produced response and its associated name.
  The callback's return value will be appended to the pending responses and processed in sequence.
  
  ## Parameters
  
    - func: A 2-arity function that receives `(response, name)` where `response` is the last produced response and `name` is its atom identifier.
  
  """
  @spec on_result(Cnt.t(), (response :: any(), name :: atom() -> any())) :: Cnt.t()
  def on_result(cnt, func) when is_function(func, 2) do
    add_on_result(cnt, func)
  end

  defguardp is_file(file) when is_binary(file) or (is_tuple(file) and elem(file, 0) == :file)

  
  
  @doc """
Queues a SendDocument response to send the given file in the current context.

Builds a SendDocument response using `document` and optional `ops`, associates it with the current message/update when present, and returns an updated `Cnt` with the response queued for delivery.

## Parameters

  - document: A file reference accepted by ExGram (for example a file path binary or `{:file, path}` tuple).
  - ops: Keyword list of options forwarded to the send action (for example `:caption`, `:reply_markup`, etc.).

## Returns

The updated `Cnt` with the SendDocument response appended.
"""
@spec answer_document(Cnt.t(), ExGram.File.file()) :: Cnt.t()
@spec answer_document(Cnt.t(), ExGram.File.file(), keyword()) :: Cnt.t()
def answer_document(cnt, document, ops \\ [])

  @doc """
  Queues a SendDocument response containing the given document and options.
  
  ## Parameters
  
    - cnt: The current context accumulator.
    - document: A file to send (either a file path as a binary or a `{:file, _}` tuple).
    - ops: Keyword list of send options (e.g., caption, reply_to_message_id).
  
  @returns The updated `Cnt.t()` with the `SendDocument` response appended.
  """
  @spec answer_document(Cnt.t(), binary() | {:file, any()}, list()) :: Cnt.t()
  def answer_document(cnt, document, ops) when is_file(document) and is_list(ops) do
    SendDocument
    |> Responses.new(%{document: document, ops: ops})
    |> add_answer(cnt)
  end

  @doc """
    Queues a document to be sent in reply to the given message.
    
    ## Parameters
    
      - cnt: The current context accumulator.
      - msg: Message map to associate the document with.
      - document: File path or `{:file, ...}` tuple representing the document to send.
    
    ## Returns
    
    The updated context with a SendDocument response queued for the provided message.
    """
    @spec answer_document(Cnt.t(), Message.t(), ExGram.File.file()) :: Cnt.t()
  def answer_document(cnt, msg, document) when is_map(msg) and is_file(document),
    do: answer_document(cnt, msg, document, [])

  @doc """
  Queues a SendDocument response attached to the given message.
  
  Associates the provided `document` and `ops` with `msg` and appends a SendDocument response to the `cnt`'s pending answers.
  
  ## Parameters
  
    - msg: Message to which the document will be sent.
    - document: File reference (path binary or `{:file, ...}` tuple) representing the document to send.
    - ops: Keyword list of send options (e.g., caption, reply_markup).
  
  """
  @spec answer_document(Cnt.t(), Message.t(), ExGram.File.file(), keyword()) :: Cnt.t()
  def answer_document(cnt, msg, document, ops) when is_map(msg) and is_file(document) do
    SendDocument
    |> Responses.new(%{document: document, ops: ops})
    |> Responses.set_msg(msg)
    |> add_answer(cnt)
  end

  @doc """
Creates an InlineKeyboardMarkup from nested button rows.

Deprecated: use `create_inline_keyboard/1` instead.

## Parameters

  - data: a list of rows, where each row is a list of button definitions (defaults to `[[]]`).
"""
@spec create_inline(list()) :: InlineKeyboardMarkup.t()
  def create_inline(data \\ [[]]), do: create_inline_keyboard(data)

  @doc """
  Builds an InlineKeyboardMarkup struct from nested keyboard row data.
  
  Accepts a list of rows where each row is a list of button definitions. Each button may be a map or a keyword list describing an inline button (e.g., `%{text: "OK", callback_data: "ok"}` or `[text: "OK", url: "https://..."]`). Defaults to an empty single-row keyboard when omitted.
  
  ## Parameters
  
    - data: List of rows (each row is a list of maps or keyword lists) describing inline buttons.
  
  ## Examples
  
      iex> ExGram.Dsl.create_inline_keyboard([[%{text: "A", callback_data: "a"}]])
      %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: [[%{text: "A", callback_data: "a"}]]}
  
  """
  @spec create_inline_keyboard([[map() | keyword()]]) :: InlineKeyboardMarkup.t()
  def create_inline_keyboard(data \\ [[]]) do
    ExGram.Cast.cast!(%{inline_keyboard: data}, InlineKeyboardMarkup)
  end

  @doc """
  Builds a ReplyKeyboardMarkup from a nested keyboard layout and optional markup options.
  
  Takes keyboard rows as a list of lists (each inner list is a row of button definitions) and merges provided options into the resulting markup. The `:keyboard` field is set to `data`.
  
  ## Parameters
  
    - data: Nested list representing keyboard rows (default: `[[]]`). Each button may be a map or a keyword list describing the button.
    - opts: Keyword or map of additional ReplyKeyboardMarkup fields (e.g., `resize_keyboard`, `one_time_keyboard`, `selective`).
  
  ## Examples
  
      iex> create_reply_keyboard([["Yes", "No"], ["Maybe"]], resize_keyboard: true)
      %ReplyKeyboardMarkup{keyboard: [["Yes", "No"], ["Maybe"]], resize_keyboard: true}
  
  """
  @spec create_reply_keyboard([[map() | keyword()]], keyword()) :: ReplyKeyboardMarkup.t()
  def create_reply_keyboard(data \\ [[]], opts \\ []) do
    opts = opts |> Map.new() |> Map.put(:keyboard, data)

    ExGram.Cast.cast!(opts, ReplyKeyboardMarkup)
  end

  @doc """
  Extracts a numeric identifier from an Update or Message.
  
  Tries to return the chat id if present; if not, returns the user id when available. Returns -1 when neither is found.
  """
  @spec extract_id(Update.t() | Message.t()) :: integer() | -1
  def extract_id(u) do
    case extract_chat(u) do
      {:ok, %{id: cid}} ->
        cid

      _ ->
        case extract_user(u) do
          {:ok, %{id: uid}} -> uid
          _ -> -1
        end
    end
  end

  @doc """
Extracts the user (`from`) field from an Update or Message.

Returns `{:ok, user}` when a `from` user is present, `:error` otherwise.
"""
@spec extract_user(Update.t() | Message.t()) :: {:ok, ExGram.Model.User.t()} | :error
  def extract_user(%{from: u}) when not is_nil(u), do: {:ok, u}
  @doc """
Extracts the user from a value that contains a nested `:message` field.

Returns `{:ok, user}` when a `User` can be extracted from the nested message, `:error` otherwise.
"""
@spec extract_user(Update.t() | Message.t()) :: {:ok, ExGram.Model.User.t()} | :error
def extract_user(%{message: m}) when not is_nil(m), do: extract_user(m)
  @doc """
Extracts the user from an update that contains an `edited_message`.

When the update has a non-nil `edited_message`, this clause attempts to obtain the user from that message and returns `{:ok, User.t()}` on success or `:error` if no user can be extracted.
"""
@spec extract_user(ExGram.Model.Update.t() | ExGram.Model.Message.t()) :: {:ok, ExGram.Model.User.t()} | :error
def extract_user(%{edited_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_channel_post: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{business_connection: %{user: u}}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{business_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{edited_business_message: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{message_reaction: %{user: u}}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{inline_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chosen_inline_result: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{callback_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{shipping_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{pre_checkout_query: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{purchased_paid_media: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{poll_answer: %{user: u}}) when not is_nil(u), do: {:ok, u}
  def extract_user(%{my_chat_member: m}) when not is_nil(m), do: extract_user(m)
  def extract_user(%{chat_member: m}) when not is_nil(m), do: extract_user(m)
  @doc """
Extracts the user from an update that contains a `chat_join_request`.

Returns `{:ok, user}` if a user can be extracted from the `chat_join_request` map, `:error` otherwise.
"""
@spec extract_user(Update.t() | Message.t()) :: {:ok, ExGram.Model.User.t()} | :error
def extract_user(%{chat_join_request: m}) when not is_nil(m), do: extract_user(m)
  @doc """
Extracts the user from an Update or Message.

Returns `{:ok, User.t()}` when a user is present, `:error` otherwise.
"""
@spec extract_user(ExGram.Model.Update.t() | ExGram.Model.Message.t()) :: {:ok, ExGram.Model.User.t()} | :error
def extract_user(_), do: :error

  @doc """
  Deprecated. Extracts the chat or group from the given update or message.
  
  Logs a deprecation warning. Returns `{:ok, chat}` when a chat/group is found, `:error` otherwise.
  """
  @spec extract_group(Update.t() | Message.t()) :: {:ok, Chat.t()} | :error
  def extract_group(update) do
    Logger.warning("extract_group/1 is deprecated, use extract_chat/1 instead")
    extract_chat(update)
  end

  @spec extract_chat(Update.t()) :: {:ok, Chat.t()} | :error
  def extract_chat(%{chat: c}) when not is_nil(c), do: {:ok, c}
  def extract_chat(%{message: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{edited_message: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{callback_query: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{business_message: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{edited_business_message: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{deleted_business_messages: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{channel_post: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{edited_channel_post: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{message_reaction: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{message_reaction_count: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{poll_answer: %{voter_chat: c}}) when not is_nil(c), do: {:ok, c}
  def extract_chat(%{my_chat_member: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{chat_member: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{chat_join_request: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{chat_boost: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(%{removed_chat_boost: m}) when not is_nil(m), do: extract_chat(m)
  def extract_chat(_), do: :error

  def extract_callback_id(%{callback_query: m}) when not is_nil(m), do: extract_callback_id(m)
  def extract_callback_id(%{id: cid, data: _data}), do: cid
  def extract_callback_id(cid) when is_binary(cid), do: cid
  def extract_callback_id(_), do: :error

  def extract_response_id(%{message_id: id}) when not is_nil(id), do: id
  def extract_response_id(%{id: id}) when not is_nil(id), do: id
  def extract_response_id(%{message: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{callback_query: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{inline_query: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{edited_message: m}) when not is_nil(m), do: extract_response_id(m)
  def extract_response_id(%{channel_message: m}) when not is_nil(m), do: extract_response_id(m)

  def extract_response_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_response_id(m)

  def extract_message_id(%{message_id: id}), do: id
  def extract_message_id(%{message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{edited_message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{channel_message: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(%{edited_channel_post: m}) when not is_nil(m), do: extract_message_id(m)
  def extract_message_id(_), do: :error

  @type update_type ::
          :message
          | :edited_message
          | :channel_post
          | :edited_channel_post
          | :business_connection
          | :business_message
          | :edited_business_message
          | :deleted_business_messages
          | :message_reaction
          | :message_reaction_count
          | :inline_query
          | :chosen_inline_result
          | :callback_query
          | :shipping_query
          | :pre_checkout_query
          | :purchased_paid_media
          | :poll
          | :poll_answer
          | :my_chat_member
          | :chat_member
          | :chat_join_request
          | :chat_boost
          | :removed_chat_boost
  @spec extract_update_type(Update.t()) :: {:ok, update_type()} | :error
  def extract_update_type(%{message: m}) when not is_nil(m), do: {:ok, :message}
  def extract_update_type(%{edited_message: m}) when not is_nil(m), do: {:ok, :edited_message}
  def extract_update_type(%{channel_post: m}) when not is_nil(m), do: {:ok, :channel_post}

  def extract_update_type(%{edited_channel_post: m}) when not is_nil(m), do: {:ok, :edited_channel_post}

  def extract_update_type(%{business_connection: m}) when not is_nil(m), do: {:ok, :business_connection}
  def extract_update_type(%{business_message: m}) when not is_nil(m), do: {:ok, :business_message}

  def extract_update_type(%{edited_business_message: m}) when not is_nil(m), do: {:ok, :edited_business_message}

  def extract_update_type(%{deleted_business_messages: m}) when not is_nil(m), do: {:ok, :deleted_business_messages}

  def extract_update_type(%{message_reaction: m}) when not is_nil(m), do: {:ok, :message_reaction}

  def extract_update_type(%{message_reaction_count: m}) when not is_nil(m), do: {:ok, :message_reaction_count}

  def extract_update_type(%{inline_query: m}) when not is_nil(m), do: {:ok, :inline_query}

  def extract_update_type(%{chosen_inline_result: m}) when not is_nil(m), do: {:ok, :chosen_inline_result}

  def extract_update_type(%{callback_query: m}) when not is_nil(m), do: {:ok, :callback_query}
  def extract_update_type(%{shipping_query: m}) when not is_nil(m), do: {:ok, :shipping_query}

  def extract_update_type(%{pre_checkout_query: m}) when not is_nil(m), do: {:ok, :pre_checkout_query}

  def extract_update_type(%{purchased_paid_media: m}) when not is_nil(m), do: {:ok, :purchased_paid_media}

  def extract_update_type(%{poll: m}) when not is_nil(m), do: {:ok, :poll}
  def extract_update_type(%{poll_answer: m}) when not is_nil(m), do: {:ok, :poll_answer}
  def extract_update_type(%{my_chat_member: m}) when not is_nil(m), do: {:ok, :my_chat_member}
  def extract_update_type(%{chat_member: m}) when not is_nil(m), do: {:ok, :chat_member}

  def extract_update_type(%{chat_join_request: m}) when not is_nil(m), do: {:ok, :chat_join_request}

  def extract_update_type(%{chat_boost: m}) when not is_nil(m), do: {:ok, :chat_boost}

  def extract_update_type(%{removed_chat_boost: m}) when not is_nil(m), do: {:ok, :removed_chat_boost}

  def extract_update_type(_), do: :error

  @type message_type ::
          :text
          | :animation
          | :audio
          | :document
          | :photo
          | :sticker
          | :story
          | :video
          | :video_note
          | :voice
          | :contact
          | :dice
          | :game
          | :poll
          | :venue
          | :location
          | :invoice
          | :successful_payment
          | :giveaway
  @doc """
Identifies the message type when the Message contains text.

Returns `{:ok, :text}` if the message has a non-nil `text` field, `:error` otherwise.
"""
@spec extract_message_type(Message.t()) :: {:ok, message_type()} | :error
  def extract_message_type(%{text: m}) when not is_nil(m), do: {:ok, :text}
  @doc """
Determines the message's content type.

When the message contains a recognized content field (for example `:animation`, `:text`, `:photo`), returns `{:ok, message_type}`; returns `:error` when no known content field is present.
"""
@spec extract_message_type(Message.t()) :: {:ok, message_type()} | :error
def extract_message_type(%{animation: m}) when not is_nil(m), do: {:ok, :animation}
  @doc """
Identifies the message as an audio message.

Checks the message for an `audio` field and classifies it as `:audio` when present.

## Parameters

  - message: A message map or struct to inspect for an `audio` media field.

"""
@spec extract_message_type(map()) :: {:ok, message_type()} | :error
def extract_message_type(%{audio: m}) when not is_nil(m), do: {:ok, :audio}
  def extract_message_type(%{document: m}) when not is_nil(m), do: {:ok, :document}
  def extract_message_type(%{photo: m}) when not is_nil(m), do: {:ok, :photo}
  def extract_message_type(%{sticker: m}) when not is_nil(m), do: {:ok, :sticker}
  def extract_message_type(%{story: m}) when not is_nil(m), do: {:ok, :story}
  def extract_message_type(%{video: m}) when not is_nil(m), do: {:ok, :video}
  def extract_message_type(%{video_note: m}) when not is_nil(m), do: {:ok, :video_note}
  def extract_message_type(%{voice: m}) when not is_nil(m), do: {:ok, :voice}
  def extract_message_type(%{contact: m}) when not is_nil(m), do: {:ok, :contact}
  def extract_message_type(%{dice: m}) when not is_nil(m), do: {:ok, :dice}
  def extract_message_type(%{game: m}) when not is_nil(m), do: {:ok, :game}
  def extract_message_type(%{poll: m}) when not is_nil(m), do: {:ok, :poll}
  def extract_message_type(%{venue: m}) when not is_nil(m), do: {:ok, :venue}
  def extract_message_type(%{location: m}) when not is_nil(m), do: {:ok, :location}
  def extract_message_type(%{invoice: m}) when not is_nil(m), do: {:ok, :invoice}

  def extract_message_type(%{successful_payment: m}) when not is_nil(m), do: {:ok, :successful_payment}

  def extract_message_type(%{giveaway: m}) when not is_nil(m), do: {:ok, :giveaway}
  def extract_message_type(_), do: :error

  def extract_inline_id_params(%{message: %{message_id: mid}} = m), do: %{message_id: mid, chat_id: extract_id(m)}

  @doc """
Builds a map of inline identifier parameters from a structure that already contains `inline_message_id`.

This clause extracts the `inline_message_id` key and returns a map containing the same key and value.
"""
@spec extract_inline_id_params(%{inline_message_id: binary()}) :: %{inline_message_id: binary()}
def extract_inline_id_params(%{inline_message_id: mid}), do: %{inline_message_id: mid}

  @doc """
No-op when the context has already been halted.

This function leaves the provided `Cnt` unchanged if `cnt.halted` is `true`.
"""
@spec send_answers(Cnt.t()) :: Cnt.t()
  def send_answers(%Cnt{halted: true} = cnt), do: cnt

  @doc """
  Processes the queued responses in the given context and marks the context as halted.
  
  When the context is not halted, executes all entries queued in `cnt.answers`, collects the resulting responses into `cnt.responses`, and sets `cnt.halted` to `true`.
  """
  @spec send_answers(Cnt.t()) :: Cnt.t()
  def send_answers(%Cnt{answers: answers, name: name, halted: false} = cnt) do
    msg = extract_msg(cnt)
    responses = send_all_answers(answers, name, msg)
    %{cnt | responses: responses, halted: true}
  end

  defp add_answer(resp, %Cnt{answers: answers} = cnt) do
    answers = answers ++ [{:response, resp}]
    %{cnt | answers: answers}
  end

  defp add_on_result(%Cnt{answers: answers} = cnt, func) do
    answers = answers ++ [{:on_result, func}]
    %{cnt | answers: answers}
  end

  defp extract_msg(%Cnt{update: %Update{} = u}) do
    u = Map.from_struct(u)
    {_, msg} = Enum.find(u, fn {_, m} -> is_map(m) and not is_nil(m) end)
    msg
  end

  defp extract_msg(_), do: nil

  defp send_all_answers(answers, name, msg), do: send_all_answers(answers, name, msg, [])

  defp send_all_answers([], _, _, responses), do: responses

  defp send_all_answers([{:response, answer} | answers], name, msg, responses) do
    response =
      answer
      |> put_name_if_not(name)
      |> Responses.set_msg(msg)
      |> Responses.execute()

    responses = responses ++ [response]

    send_all_answers(answers, name, msg, responses)
  end

  defp send_all_answers([{:on_result, callback} | answers], name, msg, responses) do
    case Enum.split(responses, -1) do
      {_, []} ->
        error = %ExGram.Error{
          code: :unknown_answer,
          message: "On Result callback should have a response before."
        }

        responses = responses ++ [{:error, error}]

        send_all_answers(answers, name, msg, responses)

      {resp, [last_response]} ->
        response = callback.(last_response, name)
        responses = resp ++ [response]
        send_all_answers(answers, name, msg, responses)
    end
  end

  defp send_all_answers([answer | answers], name, msg, responses) do
    error = %ExGram.Error{
      code: :unknown_answer,
      message: "Unknown answer: #{inspect(answer)}",
      metadata: %{answer: answer}
    }

    responses = responses ++ [{:error, error}]
    send_all_answers(answers, name, msg, responses)
  end

  defp put_name_if_not(%{ops: ops} = base, name) when is_list(ops) do
    %{base | ops: put_name_if_not(ops, name)}
  end

  defp put_name_if_not(keyword, name) do
    case {Keyword.fetch(keyword, :token), Keyword.fetch(keyword, :bot)} do
      {:error, :error} -> Keyword.put(keyword, :bot, name)
      _ -> keyword
    end
  end
end
