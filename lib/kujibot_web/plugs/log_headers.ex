defmodule KujibotWeb.Plugs.LogHeaders do
  @moduledoc """
  A plug that logs all request headers.
  """

  def init(default), do: default

  def call(conn, _opts) do
    Enum.each(conn.req_headers, fn {key, value} ->
      IO.inspect({key, value}, label: "Request Header")
    end)

    conn
  end
end
