defmodule Kujibot.Telegram.AuthenticateUser do
  # feels like this module needs a better name, authenticate telegram messages?

  @doc """
  Verifies the Telegram message against the secret token.

  """
  def verify_tg_message(conn) do
    received_token = get_received_token(conn)
    secret_token = System.get_env("TG_SECRET_TOKEN")

    received_token == secret_token
  end

  #
  # Extracts the 'x-telegram-bot-api-secret-token' header from the connection.
  #
  defp get_received_token(conn) do
    Plug.Conn.get_req_header(conn, "x-telegram-bot-api-secret-token")
    |> List.first()
  end
end
