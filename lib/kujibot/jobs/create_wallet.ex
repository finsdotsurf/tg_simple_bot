defmodule Kujibot.Jobs.CreateWallet do
  use Oban.Worker,
    queue: :wallet,
    unique: [
      keys: [:chat_id],
      period: 60
    ]

  @impl true
  def perform(%Oban.Job{args: %{"chat_id" => chat_id}}) do
    # Your job logic here
  end
end
