defmodule KujibotWeb.TelegramCommandParser do
  def parse_command("/setup-w"), do: {:ok, :set_up_wallet}
  def parse_command("Set up wallet"), do: {:ok, :set_up_wallet}
  def parse_command("🔮 Forge thy new Wallet"), do: {:ok, :forge_new_wallet}
  def parse_command("/list"), do: {:ok, :list_pairs}
  def parse_command("📜 List Pairs"), do: {:ok, :list_pairs}
  def parse_command("📜 List Featured"), do: {:ok, :list_pairs}
  def parse_command("/menu"), do: {:ok, :summon_menu}
  def parse_command("🔍 Search"), do: {:ok, :search}
  def parse_command("/start"), do: {:ok, :start}
  def parse_command("🏰 Summon Menu"), do: {:ok, :summon_menu}
  def parse_command(_), do: {:ok, :bad_command}
end
