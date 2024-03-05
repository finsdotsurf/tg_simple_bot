defmodule KujibotWeb.TelegramJSON do
  @moduledoc """
  A module for interacting with the Telegram Bot API.
  """

  require Logger
  alias HTTPoison

  @base_url "https://api.telegram.org/bot"

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
  def send_message(chat_id, response_message, bot_token) do
    url = "#{@base_url}#{bot_token}/sendMessage"
    headers = [{"Content-Type", "application/json"}]

    body =
      %{
        chat_id: chat_id,
        text: response_message
      }
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Logger.info("HTTPoison.post")

        case Jason.decode(response_body) do
          {:ok, decoded_response} ->
            Logger.info("Decoding succeeded: #{inspect(decoded_response)}")
            {:ok, decoded_response}

          {:error, _} = error ->
            Logger.error("Decoding failed: #{inspect(error)}")
            error
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Failed to send message. Status code: #{status_code}")
        {:error, :failed_request}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error occurred: #{inspect(reason)}")
        {:error, :http_error}
    end
  end

  def send_message_with_keyboard(chat_id, response_message, bot_token, keyboard) do
    url = "#{@base_url}#{bot_token}/sendMessage"
    headers = [{"Content-Type", "application/json"}]

    body =
      %{
        reply_markup: keyboard,
        chat_id: chat_id,
        text: response_message
      }
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Logger.info("HTTPoison.post")

        case Jason.decode(response_body) do
          {:ok, decoded_response} ->
            Logger.info("Decoding succeeded: #{inspect(decoded_response)}")
            {:ok, decoded_response}

          {:error, _} = error ->
            Logger.error("Decoding failed: #{inspect(error)}")
            error
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        # current code not working: [error] Failed to send message. Status code: 400
        Logger.error("Failed to send message. Status code: #{status_code}")
        {:error, :failed_request}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error occurred: #{inspect(reason)}")
        {:error, :http_error}
    end
  end
end
