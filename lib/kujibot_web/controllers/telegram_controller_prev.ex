defmodule KujibotWeb.TelegramController_prev do
  use KujibotWeb, :controller

  plug :put_view, json: KujibotWeb.TelegramJSON

  alias KujibotWeb.TelegramJSON
  alias Kujibot.Telegram.MessageAccessor
  alias Kujibot.Telegram.AuthenticateUser

  require Logger

  @doc """
  Handles incoming webhook requests from Telegram.
  """
  def index(conn, params) do
    Logger.info("RECEIVED MESSAGE: #{inspect(params)}")

    conn =
      if AuthenticateUser.verify_tg_message(conn) do
        Logger.info("AUTH SUCCESS")

        case MessageAccessor.extract_message_details(params) do
          {:ok, details} ->
            Logger.info("MESSAGE DETAILS: #{inspect(details)}")
            handle_message(details, conn)

          _error ->
            Logger.error("Failed to extract message details")
            send_resp(conn, 400, "Failed to extract message details")
        end
      else
        Logger.info("Authentication failed")
        send_resp(conn, 401, "Unauthorized")
      end
  end

  defp handle_message(details, conn) do
    with {:ok, chat_id} when is_integer(chat_id) <- Keyword.fetch(details, :chat_id),
         {:ok, text} <- Keyword.fetch(details, :text),
         {:ok, command} <- parse_command(text) do
      Logger.info("Handling message for chat_id: #{chat_id}")
      Logger.info("Parsed command: #{inspect(command)}")
      execute_command(command, chat_id, conn)
    else
      :error ->
        Logger.info("Command not recognized or missing chat_id/text")
        send_resp(conn, 200, "Command not recognized or missing chat_id/text.")

      {_, chat_id} ->
        Logger.info("No user found for chat_id: #{chat_id}")
        send_resp(conn, 200, "No user found.")
    end
  end

  defp execute_command(command, chat_id, conn) do
    response_message =
      case command do
        :start -> "Welcome, noble traveller, to our realm. How may I assist thee today?"
        :create_wallet -> "A new wallet is being forged in the depths of our vaults."
        :list_pairs -> "Behold, the pairs available in our domain are many and varied."
        _ -> "Command not recognized."
      end

    Logger.info("Sending Telegram message to chat_id #{chat_id}")
    TelegramJSON.send_message(chat_id, response_message, System.get_env("BOT_TOKEN"))
    # No need to send_resp here since the response is intended for Telegram, not the HTTP response
    conn
  end

  defp parse_command("/start"), do: {:ok, :start}
  defp parse_command("/create-wallet"), do: {:ok, :create_wallet}
  defp parse_command("/list-pairs"), do: {:ok, :list_pairs}
  defp parse_command(_), do: :error
end
