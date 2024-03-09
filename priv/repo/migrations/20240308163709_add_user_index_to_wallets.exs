defmodule Kujibot.Repo.Migrations.AddUserIdIndexToWallets do
  use Ecto.Migration

  def change do
    create index(:wallets, [:user_id])
  end
end
