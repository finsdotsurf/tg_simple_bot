defmodule Kujibot.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :user_id, references(:users, on_delete: :nilify_all), null: true
      add :wallet_name, :string, null: false
      # Storing the hash, not the actual password
      add :password_hash, :string, null: false
      timestamps()
    end

    create unique_index(:wallets, [:user_id, :wallet_name], name: :unique_user_wallet_names)
  end
end
