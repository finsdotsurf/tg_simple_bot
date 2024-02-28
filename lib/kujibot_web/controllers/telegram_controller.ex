defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  def webhook(conn, params) do
    # ensure message is in a structured format (Map) if it's a JSON string
    structured_message =
      case is_map(params) do
        true -> params
        false -> parse_json(params)
      end

    # Now, let us broadcast this structured message to the desired topic
    KujibotWeb.Endpoint.broadcast("telegram:messages", "kujibot_message", structured_message)

    send_resp(conn, 200, "OK")
  end

  # Helper function to parse JSON string into a Map
  defp parse_json(message) do
    case Jason.decode(message) do
      {:ok, decoded} -> decoded
      # or handle the error as you see fit
      {:error, _} -> %{}
    end
  end
end
