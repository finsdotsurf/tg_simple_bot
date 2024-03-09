defmodule KujibotWeb.TelegramController do
  use KujibotWeb, :controller

  plug :put_view, json: KujibotWeb.TelegramJSON

  alias KujibotWeb.TelegramJSON
  alias Kujibot.Telegram.MessageAccessor
  alias Kujibot.Telegram.AuthenticateUser
  alias Kujibot.Accounts

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

      send_error_response(conn, :unauthorized)
    end
  end

  #
  # Handles valid Telegram bot messages
  #
  defp handle_message(conn, details) do
    # chat_id is the name of the field in the message, which is the unique id of this TG user's account
    with {:ok, chat_id} when is_integer(chat_id) <- Map.fetch(details, :chat_id),
         {:ok, content} <- Map.fetch(details, :content) do
      case parse_command(content) do
        # not absolutely sure about this but I
        {:ok, command} ->
          execute_command(command, conn, chat_id, content)
      end
    else
      _ ->
        Logger.info("Command not recognized or missing chat_id/data")
        Logger.info("Invalid message format")
        send_error_response(conn, :bad_request)
    end
  end

  # Should the rest of the code be put into separate file(s)?

  defp parse_command("/create"), do: {:ok, :create_wallet_option}
  defp parse_command("/create-wallet"), do: {:ok, :create_wallet_option}
  defp parse_command("Create Wallet"), do: {:ok, :create_wallet_option}
  defp parse_command("🔮 Forge thy new Wallet"), do: {:ok, :forge_new_wallet}
  defp parse_command("/list"), do: {:ok, :list_pairs}
  defp parse_command("📜 List Pairs"), do: {:ok, :list_pairs}
  defp parse_command("📜 List Featured"), do: {:ok, :list_pairs}
  defp parse_command("/menu"), do: {:ok, :summon_menu}
  defp parse_command("🔍 Search"), do: {:ok, :search}
  defp parse_command("/start"), do: {:ok, :start}
  defp parse_command("🏰 Summon Menu"), do: {:ok, :summon_menu}
  defp parse_command(_), do: {:ok, :bad_command}

  #
  # Command execution
  # how can query parameters from buttons/commands on the user's side arrive here?
  #
  # Each message has to check the users table,
  # therefore it's possible returning_tg_user should be login_or_register_tg_user
  #
  # In either case this returns the user object, which keeps flow of control from /start simple.
  #
  defp execute_command(command, conn, chat_id, content) do
    IO.inspect(content)

    case command do
      :start ->
        case Accounts.find_or_create_tg_user(chat_id) do
          {:ok, user} ->
            if Accounts.has_wallets?(user) do
              send_main_menu_message(conn, user)
            else
              send_welcome_message(conn, user)
            end

          # otherwise send to welcome message
          # send_welcome_message(conn, chat_id)
          {:error, reason} ->
            Logger.info("find_or_create_tg_user failed:")
            IO.inspect(reason)
            send_error_response(conn, :unprocessable_entity)
        end

      :summon_menu ->
        # the menu will be where current users land or return
        case Accounts.find_or_create_tg_user(chat_id) do
          {:ok, user} ->
            send_main_menu_message(conn, user)

          {:error, reason} ->
            Logger.info("find_or_create_tg_user failed:")
            IO.inspect(reason)
            send_error_response(conn, :unprocessable_entity)
        end

      :create_wallet_option ->
        # If the user doesn't have a wallet we should arrive here
        send_create_wallet_message(conn, chat_id)

      :forge_new_wallet ->
        # expecting a user on this step
        # if no wallet, add special message that this will be the first and therefore default
        # unless they create another and set that as default
        #
        # content will at some point have callback or query data that helps prove we can trust this user
        # initiated this action
        forge_wallet(conn, chat_id, content)

      :list_pairs ->
        send_list_pairs_message(conn, chat_id, content)

      :search ->
        # set up text entry and buttons for search
        send_search_menu_message(conn, chat_id)

      :bad_command ->
        # any unmatched messages should land here
        send_bad_command_message(conn, chat_id)
    end
  end

  #### ***** ***** ***** ***** ***** ***** ***** ***** ***** ####
  ####                    <COMMANDS>  </COMMANDS>            ####
  ####                                                       ####
  ####                   In order of actions to take         ####
  #### ***** ***** ***** ***** ***** ***** ***** ***** ***** ####

  # Action 0
  # create tg_user on db,
  # prompt to create a wallet
  def send_welcome_message(conn, user) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Hearken, noble traveller, in order to partake in Kujira's bustling FIN exchange, thou must first summon a wallet to be forged within the vaults for thy bags."

    # until creating wallet works, just use FORGE WALLET to create a user entry for this tg_user (chat_idz)
    keyboard = [[%{text: "Create Wallet"}, %{text: "FAQ"}]]

    TelegramJSON.send_message(bot_token, user.telegram_user_id, text, keyboard)
    send_success_response(conn, text)
  end

  # Action 1
  # standard main menu appears if we have a user account with wallet(s)

  def send_main_menu_message(conn, user) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "To the main menu, our castle of wisdom 🏰, let us retreat."

    keyboard = [[%{text: "🔍 Search"}, %{text: "📜 List Pairs"}]]

    TelegramJSON.send_message(bot_token, user.telegram_user_id, text, keyboard)
    send_success_response(conn, text)
  end

  def send_create_wallet_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Hark! Before thee can embark on quests within Kujira's realm, thou must forge thy wallet. This sacred rite grants thee the power to trade and safeguard thy treasures."

    keyboard = [[%{text: "🔮 Forge thy new Wallet"}, %{text: "📜 List Wallets"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    send_success_response(conn, text)
  end

  defp forge_wallet(conn, chat_id, _content) do
    case Accounts.get_tg_user(chat_id) do
      {:ok, user} ->
        # We want to forge a new wallet regardless of whether the user already has wallets.
        create_and_respond_with_wallet(conn, user, chat_id)

      {:error, _reason} ->
        Logger.info("Could not find Telegram user by chat_id: #{chat_id}")
        send_error_response(conn, :unprocessable_entity)
    end
  end

  defp create_and_respond_with_wallet(conn, user, chat_id) do
    hashed_password = "123456789"

    Logger.debug("Hashed password successfully.")
    # Example wallet_params with a wallet_name included
    wallet_params = %{password_hash: hashed_password, wallet_name: "ToddsWallet"}

    case Accounts.create_wallet_for_user(user, wallet_params) do
      {:ok, _wallet} ->
        text =
          "Thy new wallet has been forged. Guard thy seed phrase as thou wouldst thy life."

        keyboard = [[%{text: "🔮 Copy Seed Phrase"}, %{text: "📜 List Wallets"}]]
        TelegramJSON.send_message(System.get_env("BOT_TOKEN"), chat_id, text, keyboard)
        send_success_response(conn, text)

      {:error, reason} ->
        Logger.error("Failed to create wallet: #{inspect(reason)}")
        send_error_response(conn, :wallet_creation_fail)
    end
  end

  # defp generate_password do
  #   # Assuming you're returning a static password for debugging
  #   password = {:ok, "123456789"}

  #   Logger.debug("generate_password output: #{inspect(password)}")

  #   password
  # end

  # defp hash_password(password) do
  #   Logger.debug("Hashing password: #{inspect(password)}")

  #   result = Bcrypt.hash_pwd_salt(password)

  #   Logger.debug("Hash result: #{inspect(result)}")

  #   case result do
  #     {:ok, hash} -> {:ok, hash}
  #     _error -> {:error, "Failed to hash password"}
  #   end
  # end

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

        :unprocessable_entity ->
          "Command not recognized or missing chat_id/text"

        :bad_request ->
          "Failed to extract message details"

        :wallet_creation_fail ->
          "Failed to create wallet."
      end

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end
end
