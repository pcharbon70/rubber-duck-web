defmodule RubberduckWebWeb.CollaborativeChannel do
  @moduledoc """
  Phoenix Channel for collaborative coding features.

  Handles real-time communication for:
  - System broadcasts (server notifications)
  - LLM chat (user ↔ Duck communication)
  - Editor collaboration (multi-user editing)
  - User presence (live user tracking)
  """

  use RubberduckWebWeb, :channel

  alias RubberduckWeb.Collaborative
  alias RubberduckWebWeb.Presence

  # Channel join patterns for different topics
  def join("session:" <> session_id, %{"type" => "system_broadcast"}, socket) do
    if authorized_for_session?(socket, session_id) do
      socket = assign(socket, :session_id, session_id)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("session:" <> session_id, %{"type" => "llm_chat"}, socket) do
    if authorized_for_session?(socket, session_id) do
      socket = assign(socket, :session_id, session_id)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("session:" <> session_id, %{"type" => "editor"}, socket) do
    if authorized_for_session?(socket, session_id) do
      socket = assign(socket, :session_id, session_id)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("session:" <> session_id, %{"type" => "presence"}, socket) do
    if authorized_for_session?(socket, session_id) do
      socket = assign(socket, :session_id, session_id)

      # Track user presence
      {:ok, _} =
        Presence.track(socket, socket.assigns.user_id, %{
          online_at: inspect(System.system_time(:second)),
          typing: false
        })

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Catch-all for invalid topics
  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid_topic"}}
  end

  # Handle system broadcast messages (server → clients)
  def handle_in("system_message", %{"content" => content}, socket) do
    # Only allow system-level processes to broadcast system messages
    if socket.assigns[:system_role] == :server do
      _topic = "session:#{socket.assigns.session_id}:system_broadcast"

      broadcast(socket, "new_system_message", %{
        content: content,
        timestamp: DateTime.utc_now(),
        type: :system_broadcast
      })

      {:reply, :ok, socket}
    else
      {:reply, {:error, %{reason: "unauthorized"}}, socket}
    end
  end

  # Handle LLM chat messages (user ↔ Duck)
  def handle_in("chat_message", %{"content" => content}, socket) do
    session_id = socket.assigns.session_id
    user_id = socket.assigns.user_id

    # Store message in session
    case Collaborative.add_chat_message(session_id, %{
           content: content,
           sender_id: user_id,
           sender_type: :user,
           timestamp: DateTime.utc_now()
         }) do
      {:ok, _session} ->
        # Broadcast to other users in the session
        _topic = "session:#{session_id}:llm_chat"

        broadcast(socket, "new_chat_message", %{
          content: content,
          sender_id: user_id,
          sender_type: :user,
          timestamp: DateTime.utc_now()
        })

        # TODO: Send to Duck LLM agent for processing
        # This will be implemented in Phase 2

        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  # Handle editor changes (collaborative editing)
  def handle_in("editor_change", %{"content" => content, "cursor_position" => position}, socket) do
    session_id = socket.assigns.session_id
    user_id = socket.assigns.user_id

    # Update session with new editor content
    case Collaborative.update_session_content(session_id, content) do
      {:ok, _session} ->
        # Broadcast editor change to other users
        _topic = "session:#{session_id}:editor"

        broadcast_from(socket, "editor_updated", %{
          content: content,
          cursor_position: position,
          updated_by: user_id,
          timestamp: DateTime.utc_now()
        })

        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  # Handle presence updates (user activity)
  def handle_in("presence_update", payload, socket) do
    user_id = socket.assigns.user_id

    Presence.update(socket, user_id, fn meta ->
      Map.merge(meta, payload)
    end)

    {:noreply, socket}
  end

  # Handle user leaving
  def terminate(_reason, _socket) do
    # Cleanup will be handled automatically by Phoenix.Presence
    :ok
  end

  # Private helper functions

  defp authorized_for_session?(socket, session_id) do
    # Check if user has access to this session
    # This should integrate with your existing authentication
    case socket.assigns[:user_id] do
      nil ->
        false

      _user_id ->
        # TODO: Implement proper session authorization
        # For now, allow any authenticated user
        case Collaborative.get_by_session_id(session_id) do
          {:ok, nil} -> false
          {:ok, _session} -> true
          {:error, _} -> false
        end
    end
  end

  # Utility functions for broadcasting system messages
  def broadcast_system_message(session_id, content) do
    topic = "session:#{session_id}:system_broadcast"

    RubberduckWebWeb.Endpoint.broadcast(topic, "new_system_message", %{
      content: content,
      timestamp: DateTime.utc_now(),
      type: :system_broadcast
    })
  end

  def broadcast_duck_response(session_id, content) do
    topic = "session:#{session_id}:llm_chat"

    RubberduckWebWeb.Endpoint.broadcast(topic, "new_chat_message", %{
      content: content,
      sender_id: "duck_agent",
      sender_type: :duck,
      timestamp: DateTime.utc_now()
    })
  end
end
