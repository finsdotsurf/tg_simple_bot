defmodule KujibotWeb.TelegramJSON do
  @moduledoc """
  A module for interacting with the Telegram Bot API.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.telegram.org/"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]

  require Logger

  @doc """
  Sends a text message via the Telegram Bot API.
  https://core.telegram.org/bots/api#sendmessage

  This function sends a text message to a specified chat using the Telegram Bot API.
  It constructs a JSON payload with the chat ID and message text, then sends it to the Telegram API's `sendMessage` endpoint.
  On success, it logs and returns the decoded response from the Telegram API.
  It handles HTTP and JSON decoding errors by logging them and returning an error tuple.

  ## Parameters

  - `chat_id`: The unique identifier for the target chat or username of the target channel (in the format @channelusername). This can be either an integer or a string.
  - `response_message`: The text of the message to be sent. Must be 1-4096 characters after entities parsing.
  - `bot_token`: The bot token provided by Telegram for authenticating API requests.

  ## Returns

  - `{:ok, decoded_response}` on success, where `decoded_response` is the decoded JSON response from the Telegram API.
  - `{:error, :failed_request}` if the request to the Telegram API fails with a non-200 status code.
  - `{:error, :http_error}` if an HTTP error occurs during the request.

  ## Examples

      iex> KujibotWeb.TelegramJSON.send_message(123456789, "Hello, World!", "botToken123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11")
      {:ok, %{"ok" => true, "result" => ...}}

      iex> KujibotWeb.TelegramJSON.send_message("channelusername", "Hello, Channel!", "botToken123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11")
      {:ok, %{"ok" => true, "result" => ...}}

  ## Notes

  - API send message parameters that may be useful:
      • message_thread_id (optional): Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
      • disable_notification: Sends the message silently. Users will receive a notification with no sound.
      • protect_content: Protects the contents of the sent message from forwarding and saving
      • reply_parameters: Description of the message to reply to: https://core.telegram.org/bots/api#replyparameters
      • reply_markup: Additional interface options.
        A JSON-serialized object for an inline keyboard, custom reply keyboard,
        instructions to remove reply keyboard or to force a reply from the user.
  -
  """

  def send_message(bot_token, chat_id, text, keyboard) do
    body = %{
      chat_id: chat_id,
      text: text,
      reply_markup: %{keyboard: keyboard, resize_keyboard: true, one_time_keyboard: true}
    }

    post("/bot#{bot_token}/sendMessage", body)
  end
end
