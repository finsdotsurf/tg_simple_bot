defmodule Kujibot.Repo do
  use Ecto.Repo,
    otp_app: :kujibot,
    adapter: Ecto.Adapters.Postgres
end
