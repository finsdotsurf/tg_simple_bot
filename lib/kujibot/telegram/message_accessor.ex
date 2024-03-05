defmodule Kujibot.Telegram.MessageAccessor do
  @doc """
  Extracts attributes from a Telegram message, regardless of whether the message is original or edited.

  ## Parameters
  - params: The incoming message parameters as a map.

  ## Returns
  A tuple {:ok, %{chat_id: chat_id, date: date, text: text, message_id: message_id, update_id: update_id}} if successful,
  or {:error, :invalid_params} if the parameters do not match the expected format.
  """
  def extract_message_details(params) do
    case get_message_or_edited(params) do
      {:ok, message} ->
        extract_details_from_message(message, params["update_id"])

      _ ->
        {:error, :invalid_params}
    end
  end

  defp get_message_or_edited(params) do
    case params do
      %{"message" => message} -> {:ok, message}
      %{"edited_message" => message} -> {:ok, message}
      _ -> {:error, :not_found}
    end
  end

  defp extract_details_from_message(message, update_id) do
    with %{
           "chat" => %{"id" => chat_id},
           "date" => date,
           "text" => text,
           "message_id" => message_id
         } <- message do
      {:ok,
       [
         {:chat_id, chat_id},
         {:date, date},
         {:text, text},
         {:message_id, message_id},
         {:update_id, update_id}
       ]}
    else
      _ -> {:error, :invalid_message_format}
    end
  end
end
