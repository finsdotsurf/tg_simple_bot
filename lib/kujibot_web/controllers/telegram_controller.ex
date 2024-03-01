defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  require Logger
  alias KujibotWeb.Endpoint

  @doc """
  Handles incoming webhook requests from Telegram.
  """
  def webhook(conn, params) do
    if verify_tg_message(conn) do
      Logger.info("Secret token matches received token.")

      # Broadcast the structured message to the desired topic.
      Endpoint.broadcast("telegram:messages", "kujibot_message", params)

      send_resp(conn, 200, "OK")
    else
      Logger.info("Secret token does not match received token.")
      # Reject the request if the token is invalid or missing.
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end

  @doc """
  Verifies the Telegram message against the secret token.
  """
  defp verify_tg_message(conn) do
    received_token = get_received_token(conn)
    secret_token = System.get_env("TG_SECRET_TOKEN")

    received_token == secret_token
  end

  @doc """
  Extracts the 'x-telegram-bot-api-secret-token' header from the connection.
  """
  defp get_received_token(conn) do
    Plug.Conn.get_req_header(conn, "x-telegram-bot-api-secret-token")
    |> List.first()
  end
end
