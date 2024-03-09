defmodule Kujibot.Repo.Migrations.AddTelegramUserIdToWallets do
  use Ecto.Migration

  #  User Deletion Handling: With the user_id references in the wallets table set to nilify_all on deletion of a user, adding the telegram_user_id provides a fallback association. Ensure your application logic checks for the presence of either user_id or telegram_user_id when handling wallets, especially in cases where you need to reassociate a wallet with a newly created user account based on the Telegram ID.

  # Data Integrity and Cleanup: Consider the data integrity and cleanup strategies for orphaned wallets (i.e., wallets with neither a valid user_id nor a telegram_user_id). Developing periodic tasks to manage or archive these orphaned records could be beneficial for maintaining database health.

  # Security Considerations: Ensure that adding the Telegram user ID to wallets does not introduce any new security vulnerabilities, especially concerning the identification and authorization of actions on wallets. Implement appropriate checks to verify the Telegram user ID's authenticity and authorization before performing wallet operations.
  def change do
    alter table(:wallets) do
      add :telegram_user_id, :bigint, null: true
    end

    # Optionally, if you plan to frequently query wallets by Telegram user ID:
    create index(:wallets, [:telegram_user_id])
  end
end
