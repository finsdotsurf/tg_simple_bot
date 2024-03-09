defmodule Kujibot.Accounts.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallets" do
    belongs_to :user, Kujibot.Accounts.User
    field :wallet_name, :string
    field :password_hash, :string
    field :telegram_user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:user_id, :wallet_name, :password_hash])
    |> validate_required([:user_id, :wallet_name, :password_hash])
  end

  # Wallet-Specific Operations: Operations specific to the wallet entity, such as
  # encrypting the wallet's seed or password before saving,
  # generating a new wallet address,
  # or other utilities specific to the nature of a wallet.

  ### Utilizing the Default Wallet

  # With the schema updated, you can now implement functionality that leverages the default wallet for quick actions. For instance, when processing a trade request, your application logic can check if the user has a default wallet set and use it automatically, falling back to asking the user to select a wallet only if no default is specified.
  # Managing the Default Wallet

  # Setting the Default Wallet: Provide functionality for users to set or change their default wallet. This might be done through a specific command in your bot or via a settings menu.

  # Handling Wallet Deletion: Ensure your application logic correctly handles cases where the default wallet is deleted. You might prompt the user to select a new default wallet or clear the default wallet field until the user manually sets a new one.

  # This feature streamlines the user experience by reducing the number of steps required for common actions, making your Telegram trading bot more user-friendly and efficient for quick trades.
end
