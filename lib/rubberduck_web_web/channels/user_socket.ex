defmodule RubberduckWebWeb.UserSocket do
  @moduledoc """
  Phoenix Socket for authenticated users.
  
  Handles WebSocket connections for collaborative features including:
  - System broadcasts
  - LLM chat
  - Editor collaboration
  - User presence tracking
  """

  use Phoenix.Socket

  # Channel route for collaborative features
  channel "session:*", RubberduckWebWeb.CollaborativeChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # Verify JWT token and authenticate user
    case AshAuthentication.Jwt.verify(token, RubberduckWeb.Accounts.User) do
      {:ok, user, _claims} ->
        socket = assign(socket, :user_id, user.id)
        socket = assign(socket, :user, user)
        {:ok, socket}
        
      {:error, _reason} ->
        :error
    end
  end

  # Fallback for connections without proper authentication
  @impl true
  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket) do
    # Use user ID as socket identifier for presence tracking
    "users_socket:#{socket.assigns.user_id}"
  end
end