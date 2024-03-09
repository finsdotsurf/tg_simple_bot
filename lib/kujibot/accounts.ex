defmodule Kujibot.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Kujibot.Repo
  alias Kujibot.Accounts.{User, UserToken, UserNotifier, Wallet}

  require Logger

  ## Database getters

  @doc """
  # Finds or creates a user based on their telegram chat_id
  ## Notes
  """
  def find_or_create_tg_user(chat_id) do
    case Repo.get_by(User, telegram_user_id: chat_id) do
      nil ->
        # Assuming you have a changeset function for creating a user
        # Adjust according to your specific user creation needs
        case create_tg_user(chat_id) do
          {:ok, user} -> {:ok, user}
          {:error, reason} -> {:error, reason}
        end

      user ->
        {:ok, user}
    end
  end

  @doc """
  Creates a new user record with a given Telegram chat ID.
  """
  def create_tg_user(chat_id) do
    %User{}
    |> User.tg_user_changeset(%{telegram_user_id: chat_id})
    |> Repo.insert()
  end

  @doc """
  Registers or finds a user based on Telegram user ID.
  ## Notes
  I think I need to break this into two functions.
  ## Examples
      iex> register_or_find_user_by_telegram_id(123456789)
      {:ok, %User{}}

  """

  def register_user_by_telegram_id(chat_id) do
    Repo.get_by(User, telegram_user_id: chat_id)
    |> case do
      nil ->
        # Since email and hashed_password can now be null, only set what's available.
        # Ensure you have a default or "placeholder" value for fields that cannot be null
        # and are not provided at the time of registration.
        user = %User{
          telegram_user_id: chat_id
          # Set other fields as necessary or leave them to be updated later
        }

        user
        |> Repo.insert()
        |> handle_insert_result()

      user ->
        {:ok, user}
    end
  end

  @doc """
  Gets a user based on their Telegram chat_id.

  ## Examples

      iex> MyApp.Accounts.get_tg_user(12345)
      {:ok, %User{}}

      iex> MyApp.Accounts.get_tg_user(-1)
      {:error, "User not found"}
  """
  def get_tg_user(chat_id) do
    case Repo.get_by(User, telegram_user_id: chat_id) do
      nil ->
        {:error, "User not found"}

      user ->
        {:ok, user}
    end
  end

  defp handle_insert_result({:ok, user}), do: {:ok, user}

  defp handle_insert_result({:error, changeset}) do
    # Handle the error case, possibly logging or wrapping the error in a user-friendly way
    {:error, changeset}
  end

  #
  # THIS MAY BE HANDY IF WE DEVISE A CALLBACK SYSTEM WITH ENCRYPTED TOKEN DATA FOR AUTO-AUTH
  # INSTEAD OF NEEDING TO LOOK USER UP ON DB
  #
  # def returning_tg_user?(chat_id) do
  #   #  search for user by tg_chat_id
  #   case Repo.get_by(User, telegram_user_id: chat_id) do
  #     nil ->
  #       {:error, :not_found}

  #     user ->
  #       {:ok, user}
  #   end
  # end

  # *********************************** WALLETS ***********************************

  @doc """
  create_wallet_for_user
    * Creates a wallet, updates the user's wallets_count, and sets the new wallet as the default if necessary, all within a single transactional context.

    • Transaction Safety: This approach ensures that all operations within the Multi are transaction-safe. If any step fails, the entire transaction is rolled back, preventing partial updates.
    • Error Handling: Ecto.Multi provides clearer mechanisms for handling errors at each step of the transaction. You can pattern match on the result of Repo.transaction/1 to handle successes and failures accordingly.
    • Optimization: This method consolidates user updates into potentially a single operation, reducing the database load.
    • Ecto.Multi.new(): Corrects the module reference to Ecto.Multi.
    • Chaining Operations: Uses Ecto.Multi.insert, Ecto.Multi.update, and Ecto.Multi.run to chain the wallet creation, user update, and conditional default wallet assignment.
    • Handling Results: Includes a handle_transaction_result/1 private function to demonstrate how you might handle the results of the transaction. This function could be tailored to suit how your application needs to respond to success or failure.
    • Conditional Logic in Multi.run: Uses Ecto.Multi.run to conditionally update the default wallet only if necessary. This step is wrapped in a function that checks if the wallet was successfully created and if the user does not already have a default wallet.
  """

  def create_wallet_for_user(user, wallet_params) do
    Logger.debug("Inside create_wallet_for_user. wallet_params: #{inspect(wallet_params)}")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :wallet,
      Wallet.changeset(%Wallet{}, Map.put(wallet_params, :user_id, user.id))
    )
    |> Ecto.Multi.update(
      :update_user,
      User.wallet_update_changeset(user, %{wallets_count: user.wallets_count + 1})
    )
    |> Ecto.Multi.run(:set_default_wallet, fn _, changes ->
      Logger.debug("Inside Ecto.Multi.run for :set_default_wallet. Changes: #{inspect(changes)}")

      case Map.get(changes, :wallet) do
        nil ->
          Logger.error("Expected :wallet in changes, but was nil. This should not happen.")
          {:error, :failed_to_create_wallet}

        wallet ->
          if is_nil(user.default_wallet_id) do
            Logger.debug("Setting default wallet as no default wallet is set for the user.")

            {:ok,
             Repo.update!(User.wallet_update_changeset(user, %{default_wallet_id: wallet.id}))}
          else
            Logger.debug("User already has a default wallet. Skipping setting default wallet.")
            {:ok, user}
          end
      end
    end)
    |> Repo.transaction()
    |> handle_transaction_result()
  end

  defp handle_transaction_result({:ok, changes}) do
    Logger.debug("Transaction succeeded: #{inspect(changes)}")
    {:ok, changes.wallet}
  end

  defp handle_transaction_result({:error, :failed_to_create_wallet}) do
    Logger.error("Wallet creation failed")
    {:error, :failed_to_create_wallet}
  end

  defp handle_transaction_result({:error, _step, reason, _changes}) do
    Logger.error("Transaction failed at step #{inspect(_step)}: #{inspect(reason)}")
    {:error, reason}
  end

  def list_user_wallets(user) do
    Repo.all(from w in Wallet, where: w.user_id == ^user.id)
  end

  def get_wallet(user, wallet_id) do
    Repo.get_by(Wallet, user_id: user.id, id: wallet_id)
  end

  def has_wallets?(user) do
    user.wallets_count > 0
  end

  def get_wallets(user) do
    wallets = Repo.all(from w in Wallet, where: w.user_id == ^user.id)

    case wallets do
      [] -> {:error, :not_found}
      _ -> {:ok, wallets}
    end
  end

  @doc """
  Authenticates a user based on Telegram user ID.

  This function assumes the user has been previously registered.
  It could be expanded to automatically register users.

  ## Examples

      iex> authenticate_by_telegram_id(123456789)
      {:ok, %User{}}

  """
  def authenticate_by_telegram_id(telegram_user_id) when is_integer(telegram_user_id) do
    Repo.get_by(User, telegram_user_id: telegram_user_id)
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
