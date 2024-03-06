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
    with {:ok, chat_id} when is_integer(chat_id) <- Map.fetch(details, :chat_id),
         {:ok, text} <- Map.fetch(details, :text) do
      case parse_command(text) do
        {:ok, command} ->
          execute_command(command, conn, chat_id)
      end
    else
      _ ->
        Logger.info("Command not recognized or missing chat_id/text")
        Logger.info("Invalid message format")
        send_error_response(conn, :bad_request)
    end
  end

  defp parse_command("/create"), do: {:ok, :create_wallet_option}
  defp parse_command("/create-wallet"), do: {:ok, :create_wallet_option}
  defp parse_command("🔮 Forge they new Wallet"), do: {:ok, :forge_new_wallet}
  defp parse_command("📜 List Featured"), do: {:ok, :list_pairs_featured}
  defp parse_command("/list"), do: {:ok, :list_pairs}
  defp parse_command("📜 List Pairs"), do: {:ok, :list_pairs}
  defp parse_command("/menu"), do: {:ok, :summon_menu}
  defp parse_command("🔍 Search"), do: {:ok, :search}
  defp parse_command("/start"), do: {:ok, :start}
  defp parse_command("🏰 Summon Menu"), do: {:ok, :summon_menu}
  defp parse_command(_), do: {:ok, :bad_command}

  # Command execution
  defp execute_command(command, conn, chat_id) do
    Logger.info(command)

    case command do
      :start ->
        send_welcome_message(conn, chat_id)

      :create_wallet_option ->
        # show commands for making new wallet

        # if no wallet yet, explain this is needed to use the bot
        send_create_wallet_message(conn, chat_id)

      :forge_new_wallet ->
        # this will allow a new wallet to be created
        # seed phrase stored as new password field in user db?
        send_forge_new_wallet_message(conn, chat_id)

      :list_pairs ->
        # examine text for search and filters or pairs
        filter = :none
        send_list_pairs_message(conn, chat_id, filter)

      :list_pairs_featured ->
        # is this the best way to set a search filter?
        filter = :featured
        send_list_pairs_message(conn, chat_id, filter)

      :summon_menu ->
        # display main menu info and buttons
        send_summon_menu_message(conn, chat_id)

      :search ->
        # set up text entry and buttons for search
        send_search_menu_message(conn, chat_id)

      :bad_command ->
        # any unmatched messages should land here
        send_bad_command_message(conn, chat_id)
    end
  end

  def send_welcome_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Hearken, noble traveller, to partake in the grand exchange of Kujira's bustling Dex, thou must first summon a wallet to be forged within the vaults for thy bags. This enchanted repository shall hold thy treasures safe and serve as thy sceptre, commanding the flows of commerce at thy whim. Venture forth to the vaults and let the forging begin!"

    keyboard = [[%{text: "Create Wallet"}, %{text: "Summon Menu"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  # ... (other command handlers)

  def send_create_wallet_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Forging a wallet here will give you the tools needed for questing with bags on Kujira's steed FIN."

    keyboard = [[%{text: "🔮 Forge they new Wallet"}, %{text: "📜 List Wallets"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_forge_new_wallet_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Your new wallet is ready. Save this seed phrase somewhere safe, we cannot retrieve this for you in the future.

      Make seed phrase copyable here too?"

    keyboard = [[%{text: "🔮 Copy Seed Phrase"}, %{text: "📜 List Wallets"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_list_pairs_message(conn, chat_id, filter) do
    bot_token = System.get_env("BOT_TOKEN")

    case filter do
      :none ->
        text =
          "Behold to the heart of bags tradeable on the Kujira dex FIN, where all paths converge and from whence all quests may be embarked."

        keyboard = [[%{text: "🔍 Search"}, %{text: "📜 List Featured"}]]
        TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
        send_success_response(conn, text)

      :featured ->
        text =
          "The Featured bags of the Kujira dex FIN, where all paths converge and from whence all quests may be embarked."

        keyboard = [[%{text: "🔍 Search"}, %{text: "🏰 Summon Menu"}]]
        TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
        send_success_response(conn, text)
    end
  end

  def send_summon_menu_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "To the main menu, our castle of wisdom 🏰, let us retreat."

    keyboard = [[%{text: "🔍 Search"}, %{text: "📜 List Pairs"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_search_menu_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Let us search for tokens & coins."

    keyboard = [[%{text: "find match"}, %{text: "go back"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_bad_command_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Alas, thy command is but a whisper in the void, unheeded by our ancient lore."

    keyboard = [[%{text: "🔍 Search"}, %{text: "🏰 Summon Menu"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  defp send_success_response(conn, message) do
    conn
    |> put_status(:ok)
    |> json(%{message: message})
  end

  defp send_error_response(conn, error) do
    response_message =
      case error do
        # :unauthorized -> "Unauthorized"
        # :unprocessable_entity -> "Command not recognized or missing chat_id/text"
        :bad_request ->
          "Failed to extract message details"
      end

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end
end
