defmodule Kujibot.Repo.Migrations.AddWalletsCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :wallets_count, :integer, default: 0, null: false
    end
  end
end
