defmodule Kujibot.Telegram.MessageAccessor do
  require Logger

  @doc """
  Extracts attributes from a Telegram message, regardless of whether the message is original or edited.

  ## Parameters
  - params: The incoming message parameters as a map.

  ## Returns
  A tuple {:ok, %{chat_id: chat_id, date: date, text: text, message_id: message_id, update_id: update_id}} if successful, or {:error, :invalid_params} if the parameters do not match the expected format.
  """
  def extract_message_details(params) do
    Logger.debug("Extracting message details from params: #{inspect(params)}")

    case get_message_or_edited(params) do
      {:ok, message} ->
        Logger.debug("Found message: #{inspect(message)}")
        extract_details_from_message(message, params["update_id"])

      _ ->
        Logger.error("Invalid params: #{inspect(params)}")
        {:error, :invalid_params}
    end
  end

  defp get_message_or_edited(params) do
    Logger.debug("Checking for message or edited_message in params: #{inspect(params)}")

    case params do
      %{"message" => message} ->
        Logger.debug("Found message: #{inspect(message)}")
        {:ok, message}

      %{"edited_message" => message} ->
        Logger.debug("Found edited_message: #{inspect(message)}")
        {:ok, message}

      _ ->
        Logger.error("No message or edited_message found in params: #{inspect(params)}")
        {:error, :not_found}
    end
  end

  defp extract_details_from_message(message, update_id) do
    Logger.debug("Extracting details from message: #{inspect(message)}")

    case message do
      %{
        "chat" => %{"id" => chat_id},
        "date" => date,
        "text" => text,
        "message_id" => message_id
      } ->
        Logger.debug("Successfully extracted message details")

        {:ok,
         %{
           chat_id: chat_id,
           date: date,
           text: text,
           message_id: message_id,
           update_id: update_id
         }}

      _ ->
        Logger.error("Invalid message format: #{inspect(message)}")
        {:error, :invalid_message_format}
    end
  end
end
