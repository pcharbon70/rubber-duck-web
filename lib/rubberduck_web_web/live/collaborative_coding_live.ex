defmodule RubberduckWebWeb.CollaborativeCodingLive do
  @moduledoc """
  Main LiveView for the collaborative coding platform.
  
  Provides the primary interface combining:
  - LLM chat assistance (user ↔ Duck agent)
  - Multi-user collaborative code editing
  - Real-time synchronization via Phoenix Channels
  """

  use RubberduckWebWeb, :live_view

  alias RubberduckWeb.Collaborative.Session
  alias RubberduckWebWeb.CollaborativeCodingLive.{
    EditorComponent,
    ChatComponent,
    UserPresenceComponent
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

        # Create or join collaborative session
        case create_or_join_session(session_id, user.id) do
          {:ok, session_record} ->
            socket =
              socket
              |> assign(:session_record, session_record)
              |> assign(:connection_state, :connected)

            # TODO: Subscribe to Phoenix Channels for real-time updates
            {:ok, socket}

          {:error, reason} ->
            {:ok, 
             socket
             |> put_flash(:error, "Failed to create session: #{inspect(reason)}")
             |> assign(:connection_state, :error)}
        end

      {:error, reason} ->
        {:ok, redirect(socket, to: ~p"/auth/sign_in?error=#{reason}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_layout", %{"config" => config}, socket) do
    layout_config = merge_layout_config(socket.assigns.layout_config, config)
    
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
  def handle_info({:connection_state_changed, state}, socket) do
    {:noreply, assign(socket, :connection_state, state)}
  end

  @impl Phoenix.LiveView
  def handle_info({:session_expired}, socket) do
    socket =
      socket
      |> put_flash(:error, "Your session has expired. Please sign in again.")
      |> redirect(to: ~p"/auth/sign_in")

    {:noreply, socket}
  end

  # Component communication handlers
  @impl Phoenix.LiveView
  def handle_info({:editor_update, update_data}, socket) do
    # Handle editor component updates
    # TODO: Broadcast to other users via channels
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:chat_message, message_data}, socket) do
    # Handle chat component updates
    # TODO: Send to Duck agent via LLM channel
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:presence_update, presence_data}, socket) do
    # Handle user presence updates
    {:noreply, socket}
  end

  # Private functions

  defp authenticate_user(session) do
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
      theme: :dark
    }
  end

  defp apply_params(socket, params) do
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
    # TODO: Persist user layout preferences
    # Could use browser localStorage via push_event or user preferences in DB
    socket
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

  defp connection_status_text(state) do
    case state do
      :connected -> "Connected"
      :connecting -> "Connecting"
      :disconnected -> "Disconnected"
      :error -> "Connection Error"
      _ -> "Unknown"
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