defmodule KujibotWeb.TelegramCommandExecutor do
  alias KujibotWeb.TelegramJSON
  alias KujibotWeb.ResponseHelper
  alias Kujibot.Accounts

  require Logger

  #
  # Command execution
  # how can query parameters from buttons/commands on the user's side arrive here?
  #
  # Each message has to check the users table,
  # therefore it's possible returning_tg_user should be login_or_register_tg_user
  #
  # In either case this returns the user object, which keeps flow of control from /start simple.
  #
  def execute_command(command, conn, chat_id, content) do
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
            ResponseHelper.send_error_response(conn, :unprocessable_entity)
        end

      :summon_menu ->
        # the menu will be where current users land or return
        case Accounts.find_or_create_tg_user(chat_id) do
          {:ok, user} ->
            send_main_menu_message(conn, user)

          {:error, reason} ->
            Logger.info("find_or_create_tg_user failed:")
            IO.inspect(reason)
            ResponseHelper.send_error_response(conn, :unprocessable_entity)
        end

      :set_up_wallet ->
        # If the user doesn't have a wallet we should arrive here
        send_setup_wallet_message(conn, chat_id)

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

    # this welcome message is arrived at when a user doesn't yet have a wallet to use on the bot

    text =
      "Hearken, noble traveller, in order to partake in Kujira's bustling FIN exchange, thou must first summon a wallet to be forged within the vaults for thy bags."

    # until creating wallet works, just use FORGE WALLET to create a user entry for this tg_user (chat_idz)
    keyboard = [[%{text: "Set up wallet"}, %{text: "FAQ"}]]

    TelegramJSON.send_message(bot_token, user.telegram_user_id, text, keyboard)
    ResponseHelper.send_success_response(conn, text)
  end

  # Action 1
  # standard main menu appears if we have a user account with wallet(s)

  def send_main_menu_message(conn, user) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "To the main menu, our castle of wisdom 🏰, let us retreat."

    keyboard = [[%{text: "🔍 Search"}, %{text: "📜 List Pairs"}]]

    TelegramJSON.send_message(bot_token, user.telegram_user_id, text, keyboard)
    ResponseHelper.send_success_response(conn, text)
  end

  def send_setup_wallet_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "ASK FOR WALLET NAME HERE, LIST ANY CRURENT WALLETS PREVENT DUPLICATE NAMES. Hark! Before thee can embark on quests within Kujira's realm, thou must forge thy wallet. This sacred rite grants thee the power to trade and safeguard thy treasures."

    keyboard = [[%{text: "🔮 Forge thy new Wallet"}, %{text: "📜 List Wallets"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    ResponseHelper.send_success_response(conn, text)
  end

  #
  #   MUST ASK FOR NAME IN PREV SCREEN FOR NAMING HERE -
  #     GOTTA COVER THE FAIL CASE FIRST, NO ERROR JUST GO BACK 1 STEP
  #
  defp forge_wallet(conn, chat_id, _content) do
    case Accounts.get_tg_user(chat_id) do
      {:ok, user} ->
        # We want to forge a new wallet regardless of whether the user already has wallets.
        create_and_respond_with_wallet(conn, user, chat_id)

      {:error, _reason} ->
        Logger.info("Could not find Telegram user by chat_id: #{chat_id}")
        ResponseHelper.send_error_response(conn, :unprocessable_entity)
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
        ResponseHelper.send_success_response(conn, text)

      {:error, reason} ->
        Logger.error("Failed to create wallet: #{inspect(reason)}")
        ResponseHelper.send_error_response(conn, :wallet_creation_fail)
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
    ResponseHelper.send_success_response(conn, text)

    #   :featured ->
    text =
      "The Featured bags of the Kujira dex FIN, where all paths converge and from whence all quests may be embarked."

    #     keyboard = [[%{text: "🔍 Search"}, %{text: "🏰 Summon Menu"}]]
    #     TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    ResponseHelper.send_success_response(conn, text)
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
    ResponseHelper.send_success_response(conn, text)
  end

  def send_bad_command_message(conn, chat_id) do
    bot_token = System.get_env("BOT_TOKEN")

    text =
      "Alas, thy command is but a whisper in the void, unheeded by our ancient lore."

    keyboard = [[%{text: "🔍 Search"}, %{text: "🏰 Summon Menu"}]]

    TelegramJSON.send_message(bot_token, chat_id, text, keyboard)
    ResponseHelper.send_success_response(conn, text)
  end
end
