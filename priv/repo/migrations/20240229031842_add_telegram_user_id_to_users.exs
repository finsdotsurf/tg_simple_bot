defmodule Kujibot.Repo.Migrations.AddTelegramUserIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :email, :citext, null: true
      modify :hashed_password, :string, null: true
      # Consider if null: false with a default value of -1 is appropriate for your use case.
      # Using null: true might be more semantically correct if the absence of a telegram_user_id is allowed.
      add :telegram_user_id, :bigint, null: true
    end

    create unique_index(:users, [:telegram_user_id], name: :users_telegram_user_id_index)
  end
end
