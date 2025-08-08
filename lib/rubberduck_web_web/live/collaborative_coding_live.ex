defmodule RubberduckWebWeb.CollaborativeCodingLive do
  @moduledoc """
  Main LiveView for the collaborative coding platform.

  Provides the primary interface combining:
  - LLM chat assistance (user ↔ Duck agent)
  - Multi-user collaborative code editing
  - Real-time synchronization via Phoenix Channels
  """

  use RubberduckWebWeb, :live_view

  alias RubberduckWebWeb.CollaborativeCodingLive.{
    ChatComponent,
    EditorComponent
  }

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    case authenticate_user(session) do
      {:ok, user} ->
        session_id = generate_session_id()

        socket =
          socket
          |> assign(:user, user)
          |> assign(:session_id, session_id)
          |> assign(:connection_state, :connecting)
          |> assign(:page_title, "Collaborative Coding - RubberDuck")
          |> assign(:layout_config, default_layout_config())
          |> assign(:duck_agent, create_duck_representation())
          |> maybe_restore_layout_preferences()
          |> assign(:active_users, %{})

        # Create or join collaborative session
        user_id = if is_map(user) && Map.has_key?(user, :id), do: user.id, else: user[:id]

        case create_or_join_session(session_id, user_id) do
          {:ok, session_record} ->
            # Initialize active users with current user
            active_users = %{
              user_id => %{
                id: user_id,
                name: user[:username] || user[:email],
                email: user[:email],
                status: :online,
                color: "#3B82F6"
              }
            }

            socket =
              socket
              |> assign(:session_record, session_record)
              |> assign(:connection_state, :connected)
              |> assign(:active_users, active_users)

            # Subscribe to Phoenix Channels for real-time updates
            session_id = socket.assigns.session_id

            Phoenix.PubSub.subscribe(
              RubberduckWeb.PubSub,
              "session:#{session_id}:system_broadcast"
            )

            Phoenix.PubSub.subscribe(RubberduckWeb.PubSub, "session:#{session_id}:llm_chat")

            {:ok, socket}

          {:error, reason} ->
            {:ok,
             socket
             |> put_flash(:error, "Failed to create session: #{inspect(reason)}")
             |> assign(:connection_state, :error)}
        end

      {:error, reason} ->
        {:ok, redirect(socket, to: ~p"/sign-in?error=#{reason}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_layout", %{"config" => config}, socket) do
    # Validate and constrain the layout configuration
    validated_config = validate_layout_config(config)
    layout_config = merge_layout_config(socket.assigns.layout_config, validated_config)

    socket =
      socket
      |> assign(:layout_config, layout_config)
      |> persist_layout_preferences(layout_config)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_panel", %{"panel" => panel}, socket) do
    layout_config = toggle_panel_visibility(socket.assigns.layout_config, panel)

    socket = assign(socket, :layout_config, layout_config)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("layout_restored", %{"layout" => layout_data}, socket)
      when is_map(layout_data) do
    # Apply restored layout from localStorage
    validated_config = validate_layout_config(layout_data)
    layout_config = merge_layout_config(socket.assigns.layout_config, validated_config)

    socket = assign(socket, :layout_config, layout_config)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("layout_restored", _params, socket) do
    # No saved layout found, keep defaults
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:connection_state_changed, state}, socket) do
    {:noreply, assign(socket, :connection_state, state)}
  end

  @impl Phoenix.LiveView
  def handle_info({:session_expired}, socket) do
    socket =
      socket
      |> put_flash(:error, "Your session has expired. Please sign in again.")
      |> redirect(to: ~p"/sign-in")

    {:noreply, socket}
  end

  # Component communication handlers
  @impl Phoenix.LiveView
  def handle_info({:editor_update, _update_data}, socket) do
    # Handle editor component updates
    # TODO: Broadcast to other users via channels
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:chat_message, _message_data}, socket) do
    # Handle chat component updates
    # TODO: Send to Duck agent via LLM channel
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_update, _presence_data}, socket) do
    # Handle user presence updates
    {:noreply, socket}
  end

  # Handle system broadcast messages from Phoenix Channels
  @impl Phoenix.LiveView
  def handle_info(
        %Phoenix.Socket.Broadcast{event: "new_system_message", payload: payload},
        socket
      ) do
    # Forward system message to chat component
    send_update(ChatComponent, id: "chat-desktop", system_message: payload)
    send_update(ChatComponent, id: "chat-mobile", system_message: payload)

    {:noreply, socket}
  end

  # Handle new chat messages from Phoenix Channels
  @impl Phoenix.LiveView
  def handle_info(%Phoenix.Socket.Broadcast{event: "new_chat_message", payload: payload}, socket) do
    # Forward chat message to chat component
    send_update(ChatComponent, id: "chat-desktop", new_message: payload)
    send_update(ChatComponent, id: "chat-mobile", new_message: payload)

    {:noreply, socket}
  end

  # Private functions

  defp authenticate_user(session) do
    # Check for demo user first
    if demo_user = session["current_user"] do
      if demo_user[:is_demo] == true do
        {:ok, demo_user}
      else
        authenticate_regular_user(session)
      end
    else
      authenticate_regular_user(session)
    end
  end

  defp authenticate_regular_user(session) do
    with token when is_binary(token) <- session["user_token"],
         {:ok, user, _claims} <- AshAuthentication.Jwt.verify(token, RubberduckWeb.Accounts.User) do
      {:ok, user}
    else
      nil -> {:error, "not_authenticated"}
      {:error, _reason} -> {:error, "invalid_token"}
    end
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp create_or_join_session(session_id, user_id) do
    # For demo users, create a temporary session
    if is_binary(user_id) && String.starts_with?(user_id, "demo_") do
      {:ok,
       %{
         id: session_id,
         session_id: session_id,
         creator_id: user_id,
         session_name: "Demo Collaborative Session",
         is_demo: true,
         created_at: DateTime.utc_now()
       }}
    else
      # Try to find existing session first
      case RubberduckWeb.Collaborative.get_by_session_id(session_id) do
        {:ok, nil} ->
          # Create new session
          RubberduckWeb.Collaborative.start_session(%{
            session_id: session_id,
            creator_id: user_id,
            session_name: "Collaborative Session"
          })

        {:ok, existing_session} ->
          # Join existing session
          RubberduckWeb.Collaborative.join_session(existing_session, %{user_id: user_id})

        {:error, reason} ->
          {:error, reason}
      end
    end
  rescue
    error ->
      {:error, error}
  end

  defp create_duck_representation do
    %{
      id: "duck_agent",
      name: "Duck",
      type: :llm_agent,
      status: :available,
      capabilities: [:code_analysis, :suggestions, :explanations]
    }
  end

  defp default_layout_config do
    %{
      editor_width_percent: 70,
      chat_width_percent: 30,
      panels: %{
        editor: %{visible: true, collapsed: false},
        chat: %{visible: true, collapsed: false},
        presence: %{visible: true, collapsed: false}
      },
      mobile_layout: :stacked,
      theme: :dark,
      # Minimum widths in percentages (based on 1200px viewport)
      # ~400px
      min_editor_percent: 33,
      # ~280px
      min_chat_percent: 23,
      max_editor_percent: 85,
      max_chat_percent: 67
    }
  end

  defp validate_layout_config(config) do
    # Get the widths, using current defaults if not provided
    editor_percent = Map.get(config, "editor_width_percent", 70)
    chat_percent = Map.get(config, "chat_width_percent", 30)

    # Ensure they're integers
    editor_percent =
      if is_binary(editor_percent), do: String.to_integer(editor_percent), else: editor_percent

    chat_percent =
      if is_binary(chat_percent), do: String.to_integer(chat_percent), else: chat_percent

    # Apply constraints
    # Between 33% and 85%
    editor_percent = max(33, min(85, editor_percent))
    # Between 23% and 67%
    chat_percent = max(23, min(67, chat_percent))

    # Ensure they add up to 100%
    total = editor_percent + chat_percent

    {final_editor_percent, final_chat_percent} =
      if total != 100 do
        # Adjust chat percentage to make total 100%
        chat_percent = 100 - editor_percent
        # Re-validate chat percentage
        chat_percent = max(23, min(67, chat_percent))
        # If chat is still invalid, adjust editor too
        if chat_percent < 23 or chat_percent > 67 do
          # Default to 70/30
          {70, 30}
        else
          {editor_percent, chat_percent}
        end
      else
        {editor_percent, chat_percent}
      end

    Map.merge(config, %{
      "editor_width_percent" => final_editor_percent,
      "chat_width_percent" => final_chat_percent
    })
  end

  defp apply_params(socket, _params) do
    # Handle URL parameters for sharing sessions, deep linking, etc.
    socket
  end

  defp merge_layout_config(current_config, updates) do
    Map.merge(current_config, updates, fn
      :panels, current_panels, update_panels ->
        deep_merge_panels(current_panels, update_panels)

      _key, _current, new ->
        new
    end)
  end

  defp deep_merge_panels(current_panels, update_panels) do
    Map.merge(current_panels, update_panels, fn _key, current, update ->
      Map.merge(current, update)
    end)
  end

  defp toggle_panel_visibility(config, panel_name) do
    panel_atom = String.to_existing_atom(panel_name)

    put_in(
      config,
      [:panels, panel_atom, :visible],
      !get_in(config, [:panels, panel_atom, :visible])
    )
  end

  defp persist_layout_preferences(socket, layout_config) do
    # Send layout config to browser for localStorage persistence
    socket
    |> push_event("persist_layout", %{
      editor_width_percent: layout_config.editor_width_percent,
      chat_width_percent: layout_config.chat_width_percent
    })
  end

  defp maybe_restore_layout_preferences(socket) do
    # Send a request to restore layout from localStorage
    # The browser will respond with the saved layout or null
    push_event(socket, "restore_layout", %{})
  end

  # Template helper functions

  defp connection_status_badge_class(state) do
    case state do
      :connected -> "badge-success"
      :connecting -> "badge-warning"
      :disconnected -> "badge-error"
      :error -> "badge-error"
      _ -> "badge-neutral"
    end
  end

  defp connection_issue_message(state) do
    case state do
      :disconnected ->
        "Lost connection to the server. Your work is saved locally and will sync when reconnected."

      :error ->
        "Connection error occurred. Please check your network connection and try again."

      _ ->
        "Experiencing connection issues. Please wait while we attempt to reconnect."
    end
  end
end
