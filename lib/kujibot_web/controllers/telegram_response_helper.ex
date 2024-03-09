defmodule KujibotWeb.ResponseHelper do
  import Plug.Conn
  # Import only the json/2 function
  import Phoenix.Controller, only: [json: 2]

  def send_success_response(conn, message) do
    conn
    |> put_status(:ok)
    |> json(%{message: message})
  end

  def send_error_response(conn, error) do
    response_message =
      case error do
        :unauthorized ->
          "Unauthorized"

        :unprocessable_entity ->
          "Command not recognized or missing chat_id/text"

        :bad_request ->
          "Failed to extract message details"

        :wallet_creation_fail ->
          "Failed to create wallet."
      end

    conn
    |> put_status(:ok)
    |> json(%{message: response_message})
  end
end
