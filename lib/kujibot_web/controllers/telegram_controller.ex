defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  require Logger

  def webhook(conn, params) do
    # conn
    # |> KujibotWeb.Plugs.LogHeaders.call(%{})

    received_token =
      Plug.Conn.get_req_header(conn, "x-telegram-bot-api-secret-token") |> List.first()

    secret_token = System.get_env("TG_SECRET_TOKEN")

    if received_token == secret_token do
      Logger.info("secret token matches recieved token")
      # ensure message is in a structured format (Map) if it's a JSON string
      structured_message =
        case is_map(params) do
          true -> params
          false -> parse_json(params)
        end

      # Now, let us broadcast this structured message to the desired topic
      KujibotWeb.Endpoint.broadcast("telegram:messages", "kujibot_message", structured_message)
      send_resp(conn, 200, "OK")
    else
      Logger.info("secret token != recieved token")
      # Invalid or missing token, reject the request
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
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
