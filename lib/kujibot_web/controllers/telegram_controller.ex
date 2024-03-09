defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  plug :put_view, json: KujibotWeb.TelegramJSON

  alias Kujibot.Telegram.AuthenticateUser
  alias Kujibot.Telegram.MessageAccessor

  alias KujibotWeb.TelegramCommandParser
  alias KujibotWeb.TelegramCommandExecutor
  alias KujibotWeb.ResponseHelper

  require Logger

  @doc """
  Receives incoming webhook requests from Telegram.
  """
  def index(conn, params) do
    # checks bot_token against secret_token
    if AuthenticateUser.verify_tg_message(conn) do
      # grab all needed info our bot's latest message
      case MessageAccessor.extract_message_details(params) do
        {:ok, details} ->
          # parse and execute command
          handle_message(conn, details)

        _error ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Failed to extract message details"})
      end
    else
      Logger.info("FAKE TELEGRAM MESSAGE")

      ResponseHelper.send_error_response(conn, :unauthorized)
    end
  end

  #
  # Handles valid Telegram bot messages
  #
  defp handle_message(conn, details) do
    # chat_id is the name of the field in the message, which is the unique id of this TG user's account
    with {:ok, chat_id} when is_integer(chat_id) <- Map.fetch(details, :chat_id),
         {:ok, content} <- Map.fetch(details, :content) do
      case TelegramCommandParser.parse_command(content) do
        # not absolutely sure about this but I
        {:ok, command} ->
          TelegramCommandExecutor.execute_command(command, conn, chat_id, content)
      end
    else
      _ ->
        Logger.info("Command not recognized or missing chat_id/data")
        Logger.info("Invalid message format")
        ResponseHelper.send_error_response(conn, :bad_request)
    end
  end
end
