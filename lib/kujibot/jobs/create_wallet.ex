defmodule Kujibot.Jobs.CreateWallet do
  use Oban.Worker,
    queue: "wallet",
    unique: [
      period: 60,
      fields: [:args],
      states: [:available, :scheduled, :executing]
    ]

  @impl true
  def perform(%{"chat_id" => chat_id} = _args) do
    # Perform your task here. This is where you check if the expected info is present and then proceed.
    # If the task is completed, this function should return `:ok` or a similar success indicator.
  end
end
