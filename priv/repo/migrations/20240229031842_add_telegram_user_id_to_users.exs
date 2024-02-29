defmodule Kujibot.Repo.Migrations.AddTelegramUserIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :email, :citext, null: true
      modify :hashed_password, :string, null: true
      add :telegram_user_id, :bigint, null: false, default: -1
    end

    create unique_index(:users, [:telegram_user_id])
  end
end
