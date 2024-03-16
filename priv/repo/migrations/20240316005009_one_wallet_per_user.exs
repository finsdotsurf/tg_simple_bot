defmodule Kujibot.Repo.Migrations.OneWalletPerUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove :wallets_count
      remove :default_wallet_id
      add :wallet_password_hash, :string
    end

    # Optionally, drop the wallets table if it's no longer needed
    drop table(:wallets)
  end

  def down do
    # To revert your changes, define the opposite actions here
    create table(:wallets) do
      add :user_id, references(:users)
      add :password_hash, :string
      add :telegram_user_id, :bigint, null: true
      timestamps()
    end

    alter table(:users) do
      add :wallets_count, :integer, default: 0
      add :default_wallet_id, references(:wallets)
      remove :wallet_password_hash
      # Revert any other changes you made
    end
  end
end
