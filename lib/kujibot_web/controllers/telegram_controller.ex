defmodule KujibotWeb.TelegramController do
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
    if AuthenticateUser.verify_tg_message(conn) do
      case MessageAccessor.extract_message_details(params) do
        {:ok, details} ->
          handle_message(conn, details)

        _error ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Failed to extract message details"})
      end
    else
      Logger.info("FAKE TELEGRAM MESSAGE")

      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Unauthorized"})
    end
  end

  defp handle_message(conn, details) do
    with {:ok, chat_id} when is_integer(chat_id) <- Keyword.fetch(details, :chat_id),
         {:ok, text} <- Keyword.fetch(details, :text),
         {:ok, command} <- parse_command(text) do
      execute_command(command, conn, chat_id)
    else
      _ ->
        Logger.info("Command not recognized or missing chat_id/text")

        conn
        # Adjust this status code based on your application's needs
        |> put_status(:ok)
        |> json(%{message: "Command not recognized or missing chat_id/text."})
    end
  end

  defp parse_command("/start"), do: {:ok, :start}
  defp parse_command("/create-wallet"), do: {:ok, :create_wallet}
  defp parse_command("/list-pairs"), do: {:ok, :list_pairs}
  defp parse_command(_), do: {:ok, :bad_command}

  # Command execution
  defp execute_command(:start, conn, chat_id) do
    send_welcome_message(conn, chat_id)
  end

  defp execute_command(:create_wallet, conn, chat_id) do
    # Logic to create a wallet
    response_message = "A new wallet is being forged in the depths of our vaults."
    send_json_message(conn, chat_id, response_message)
  end

  defp execute_command(:list_pairs, conn, chat_id) do
    # Logic to list trading pairs
    response_message = "Behold, the pairs available in our domain are many and varied."
    send_json_message(conn, chat_id, response_message)
  end

  defp execute_command(:bad_command, conn, chat_id) do
    response_message =
      "Alas, thy command is but a whisper in the void, unheeded by our ancient lore."

    send_error_message(conn, chat_id, response_message)
  end

  # Example of sending a welcome message with a custom keyboard
  defp send_welcome_message(conn, chat_id) do
    response_message = "Welcome, noble traveller, to our realm. How may I assist thee today?"

    keyboard = %{
      inline_keyboard: [
        %{text: "Pray, inform me of the hours thy establishment doth keep?"},
        %{text: "I beseech thee, might I track the progress of mine order?"},
        %{text: "How doth one report an issue most vexing to thy service?"}
      ],
      resize_keyboard: true,
      one_time_keyboard: true
    }

    bot_token = System.get_env("BOT_TOKEN")
    TelegramJSON.send_message_with_keyboard(chat_id, response_message, bot_token, keyboard)

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end

  # Example of sending an error message
  defp send_error_message(conn, chat_id, response_message) do
    # Here, you can also include a keyboard similar to the send_welcome_message function
    bot_token = System.get_env("BOT_TOKEN")
    TelegramJSON.send_message(chat_id, response_message, bot_token)

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end

  defp send_json_message(conn, chat_id, response_message) do
    Logger.info("Sending Telegram message to chat_id #{chat_id}")
    bot_token = System.get_env("BOT_TOKEN")
    TelegramJSON.send_message(chat_id, response_message, bot_token)

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end
end
