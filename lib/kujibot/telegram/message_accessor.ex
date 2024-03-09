defmodule Kujibot.Telegram.MessageAccessor do
  require Logger

  @doc """
  Extracts attributes from a Telegram message, regardless of whether the message is an original message, edited message, callback query, or a chosen inline result.

  ## Parameters
  - params: The incoming message parameters as a map.

  ## Returns
  A tuple {:ok, %{message_type: message_type, content: content, chat_id: chat_id, date: date, message_id: message_id, update_id: update_id}} if successful, or {:error, :invalid_params} if the parameters do not match the expected format.
  """
  def extract_message_details(params) do
    Logger.debug("Extracting message details from params: #{inspect(params)}")

    with {:ok, {message_type, message}} <- get_message_or_special(params),
         {:ok, extracted_details} <-
           extract_details_from_message(message_type, message, params["update_id"]) do
      Logger.debug("Successfully extracted message details")
      {:ok, extracted_details}
    else
      _ ->
        Logger.error("Invalid params or unhandled message type: #{inspect(params)}")
        {:error, :invalid_params}
    end
  end

  defp get_message_or_special(params) do
    Logger.debug("Checking for various types of messages in params: #{inspect(params)}")

    cond do
      params["message"] ->
        {:ok, {"message", params["message"]}}

      params["edited_message"] ->
        {:ok, {"edited_message", params["edited_message"]}}

      params["callback_query"] ->
        {:ok, {"callback_query", params["callback_query"]}}

      params["chosen_inline_result"] ->
        {:ok, {"chosen_inline_result", params["chosen_inline_result"]}}

      true ->
        Logger.error("No recognized message type found in params: #{inspect(params)}")
        {:error, :not_found}
    end
  end

  defp extract_details_from_message(message_type, message, update_id) do
    Logger.debug("Extracting details based on message type: #{message_type}")

    common_details = %{
      message_type: message_type,
      update_id: update_id,
      chat_id: get_chat_id(message, message_type),
      message_id: get_message_id(message, message_type),
      date: get_date(message, message_type)
    }

    content =
      case message_type do
        "message" -> message["text"]
        "edited_message" -> message["text"]
        "callback_query" -> message["data"]
        "chosen_inline_result" -> message["query"]
        _ -> nil
      end

    {:ok, Map.put(common_details, :content, content)}
  end

  defp get_chat_id(message, message_type) do
    case message_type do
      "callback_query" -> message["from"]["id"]
      "chosen_inline_result" -> message["from"]["id"]
      _ -> message["chat"]["id"]
    end
  end

  defp get_message_id(message, message_type) do
    case message_type do
      "chosen_inline_result" -> message["result_id"]
      "callback_query" -> message["message"]["message_id"]
      _ -> message["message_id"]
    end
  end

  defp get_date(message, message_type) do
    case message_type do
      # Chosen inline results do not have a direct date field
      "chosen_inline_result" -> nil
      "callback_query" -> message["message"]["date"]
      _ -> message["date"]
    end
  end
end
