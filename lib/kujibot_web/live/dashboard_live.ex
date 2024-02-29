defmodule KujibotWeb.DashboardLive do
  use KujibotWeb, :live_view

  def mount(_params, _session, socket) do
    KujibotWeb.Endpoint.subscribe("telegram:messages")

    # The mount/3 function initializes the LiveView.
    # send(self(), :messages)

    # Initialize the :messages assign.
    {:ok,
     socket
     |> assign(:messages, [])}
  end

  # Process incoming messages on the "telegram:messages" topic.
  # This function should update the socket's assigns with the new message,
  # adding it to a list of messages for display
  def handle_info(%{event: "kujibot_message", payload: message}, socket) do
    # Extract desired information from message
    id = message["message"]["chat"]["id"]
    username = message["message"]["chat"]["username"]
    text = message["message"]["text"]
    # secret = message["message"]["secret"]

    # Construct new map with this information
    simple_message = %{
      id: id,
      username: username,
      text: text
    }

    # Prepending the new, refined message to the list of messages
    messages = [simple_message | socket.assigns.messages]

    {:noreply, assign(socket, :messages, messages)}
  end
end
