defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  plug :put_view, json: KujibotWeb.TelegramJSON

  alias KujibotWeb.TelegramJSON
  alias Kujibot.Telegram.MessageAccessor
  alias Kujibot.Telegram.AuthenticateUser
  alias Kujibot.Accounts

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
          execute_command(command, conn, chat_id, details)
      end
    else
      _ ->
        Logger.info("Command not recognized or missing chat_id/text")
        Logger.info("Invalid message format")
        send_error_response(conn, :bad_request)
    end
  end

  # This code and on down should be put into:
  #   kujibot/telegram/parse_commands.ex
  #   kujibot/telegram/execute_commands.ex

  defp parse_command("/create"), do: {:ok, :create_wallet_option}
  defp parse_command("/create-wallet"), do: {:ok, :create_wallet_option}
  defp parse_command("Create Wallet"), do: {:ok, :create_wallet_option}
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
  # text me be where query parameters are
  defp execute_command(command, conn, chat_id, text) do
    IO.inspect(text)

    case command do
      :start ->
        case Accounts.returning_tg_user?(chat_id) do
          {:ok, _user} ->
            # when AuthenticateUser.has_wallet?(chat_id) ->
            send_main_menu_message(conn, chat_id)

          _ ->
            send_welcome_message(conn, chat_id)
        end

      :create_wallet_option ->
        # show commands for forging a new wallet
        send_create_wallet_message(conn, chat_id)

      :forge_new_wallet ->
        # Encapsulating wallet creation logic
        forge_wallet(conn, chat_id)

      :list_pairs ->
        send_list_pairs_message(conn, chat_id, text)

      :summon_menu ->
        # display main menu info and buttons
        send_main_menu_message(conn, chat_id)

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
      "Hearken, noble traveller, in order to partake in Kujira's bustling FIN exchange, thou must first summon a wallet to be forged within the vaults for thy bags."

    # until creating wallet works, just use FORGE WALLET to create a user entry for this tg_user (chat_idz)
    keyboard = [[%{text: "Create Wallet"}, %{text: "FAQ"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_create_wallet_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    # BEFORE IMPLEMENTING WALLET CREATION (MAP OF WALLETS BY NAME)
    # CREATE A USER ACCOUNT FOR THIS TG_USER IN THE NEXT STEP (AGREEING TO FORGE A WALLET)

    case Accounts.register_user_by_telegram_id(chat_id) do
      user ->
        # tg user hath been registered
        text =
          "tg user hath been registered"

        # if already has wallet, offer to create another one

        keyboard = [[%{text: "🔮 Forge they new Wallet"}, %{text: "📜 List Wallets"}]]

        TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
        send_success_response(conn, text)

      nil ->
        # if no wallet, explain more about being ready to save the seed phrase that will be displayed, and not to let anyone around you see it
        text =
          "Forging a wallet here will give you the tools needed for questing with bags on Kujira's steed FIN."

        # if already has wallet, offer to create another one

        keyboard = [[%{text: "🔮 Forge they new Wallet"}, %{text: "📜 List Wallets"}]]

        TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
        error = :unauthorized
        send_error_response(conn, error)
    end
  end

  defp forge_wallet(conn, chat_id) do
    # Assuming a function to create a wallet and save the seed phrase
    # wallet = Wallet.create_for_user(conn.assigns.user)

    # Consider using Ecto for interacting with the database and adding a field for the seed phrase securely
    text = "Thy new wallet has been forged. Guard thy seed phrase as thou wouldst thy life."
    keyboard = [[%{text: "🔮 Copy Seed Phrase"}, %{text: "📜 List Wallets"}]]

    TelegramJSON.send_message(System.get_env("BOT_TOKEN"), chat_id, text, keyboard)
    # ResponseSender.send_success_response(conn, text)
    send_success_response(conn, text)
  end

  def send_list_pairs_message(conn, chat_id, text) do
    bot_token = System.get_env("BOT_TOKEN")

    # Dynamically determining the filter
    # filter = determine_filter(text)

    # case filter do
    # match on anything else in the text field
    # can be a list filter (featured, usk, usdc, all, star) and/or a coin/token
    # find all trading pairs based on this
    # or 2 coin/token tickers (denom in the api)
    # go to trading view for this pair if found

    # list_action set: describes the exact query make for listing denom pair(s)
    # end

    # case list_action do
    #  :none ->
    reply_message =
      "Behold to the heart of bags tradeable on the Kujira dex FIN, where all paths converge and from whence all quests may be embarked."

    keyboard = [[%{text: "🔍 Search"}, %{text: "📜 List Featured"}]]
    TelegramJSON.send_message(bot_token, chat_id, reply_message, keyboard)
    send_success_response(conn, text)

    #   :featured ->
    text =
      "The Featured bags of the Kujira dex FIN, where all paths converge and from whence all quests may be embarked."

    #     keyboard = [[%{text: "🔍 Search"}, %{text: "🏰 Summon Menu"}]]
    #     TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
    # end
  end

  # def determine_filter(text) do
  # filter data is probably going to be in the text field
  # case text do
  # match on anything after search
  # can be a list filter (featured, usk, usdc, all, star) and/or a coin/token
  # find all trading pairs based on this
  # or 2 coin/token tickers
  # go to trading view for this pair if found
  # end
  # end

  def send_main_menu_message(conn, chat_id) do
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
        :unauthorized ->
          "Unauthorized"

        # :unprocessable_entity -> "Command not recognized or missing chat_id/text"
        :bad_request ->
          "Failed to extract message details"
      end

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end
end
