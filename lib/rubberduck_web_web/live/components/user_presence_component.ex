defmodule RubberduckWebWeb.CollaborativeCodingLive.UserPresenceComponent do
  @moduledoc """
  LiveView component for user presence tracking.

  Displays active users in the collaborative session (excluding Duck).
  """

  use RubberduckWebWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:active_users, %{})
      |> assign(:presence_state, %{})

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> update_presence_state()

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_user_info", %{"user_id" => _user_id}, socket) do
    # Toggle expanded user info view
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="presence-container h-full bg-base-100">
      
    <!-- Presence header -->
      <div class="presence-header px-4 py-3 border-b border-base-300">
        <h3 class="text-sm font-semibold text-base-content flex items-center gap-2">
          👥 Active Users
          <div class="badge badge-neutral badge-sm">
            {user_count(@active_users)}
          </div>
        </h3>
      </div>
      
    <!-- Users list -->
      <div class="users-list space-y-2 p-3">
        
    <!-- Current user (you) -->
        <div class="card card-compact bg-primary/10 border border-primary/20">
          <div class="card-body">
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content w-8 rounded-full">
                  <span class="text-xs font-bold">
                    {String.first(@user.email) |> String.upcase()}
                  </span>
                </div>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <p class="text-sm font-semibold text-base-content">You</p>
                  <div class="badge badge-primary badge-sm">Host</div>
                </div>
                <p class="text-xs text-base-content/60 truncate">
                  {@user.email}
                </p>
              </div>

              <div class="indicator">
                <span
                  class="indicator-item badge badge-success badge-xs"
                  title="Online"
                  aria-label="Online"
                >
                </span>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Other active users -->
        <%= for {user_id, user_data} <- @active_users do %>
          <%= if user_id != @user.id do %>
            <div class="card card-compact bg-base-200 hover:bg-base-300 transition-colors">
              <div class="card-body">
                <div class="flex items-center gap-3">
                  <div class="avatar placeholder">
                    <div class={[
                      "w-8 rounded-full text-white text-xs font-medium",
                      user_avatar_color(user_data)
                    ]}>
                      <span>{user_avatar_text(user_data)}</span>
                    </div>
                    
    <!-- Typing indicator -->
                    <%= if user_data[:typing] do %>
                      <div class="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-accent rounded-full border-2 border-base-100">
                        <span class="loading loading-ring loading-xs"></span>
                      </div>
                    <% end %>
                  </div>

                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <p class="text-sm font-medium text-base-content truncate">
                        {user_data.name || "Anonymous"}
                      </p>
                      <%= if user_data[:cursor_position] do %>
                        <div class="badge badge-ghost badge-xs">
                          Line {user_data.cursor_position.line}
                        </div>
                      <% end %>
                    </div>

                    <%= if user_data.email do %>
                      <p class="text-xs text-base-content/60 truncate">
                        {user_data.email}
                      </p>
                    <% end %>
                  </div>

                  <div class="indicator">
                    <span
                      class={[
                        "indicator-item badge badge-xs",
                        user_status_badge_class(user_data)
                      ]}
                      title={user_status_text(user_data)}
                      aria-label={user_status_text(user_data)}
                    >
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
        
    <!-- Duck agent representation -->
        <div class="card card-compact bg-warning/10 border border-warning/20">
          <div class="card-body">
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-warning text-warning-content w-8 rounded-full">
                  <img src="/images/rubberduck.svg" alt="Duck" class="w-4 h-4" />
                </div>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2">
                  <p class="text-sm font-semibold text-base-content">
                    Duck Assistant
                  </p>
                  <div class="badge badge-warning badge-sm">AI</div>
                </div>
                <p class="text-xs text-base-content/60">
                  Your coding assistant
                </p>
              </div>

              <div class="indicator">
                <span
                  class={[
                    "indicator-item badge badge-xs",
                    duck_status_badge_class(@duck_agent.status)
                  ]}
                  title={duck_status_text(@duck_agent.status)}
                  aria-label={duck_status_text(@duck_agent.status)}
                >
                </span>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Empty state when no other users -->
        <%= if user_count(@active_users) <= 1 do %>
          <div class="card bg-base-200">
            <div class="card-body items-center text-center">
              <div class="text-4xl mb-2">👥</div>
              <p class="text-sm text-base-content/60">No other users online</p>
              <p class="text-xs text-base-content/40 mt-1">Share your session link to collaborate</p>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- Session info footer -->
      <div class="border-t border-base-300 p-3">
        <div class="flex items-center justify-between text-xs text-base-content/60">
          <span>Session: {String.slice(@session_id, 0, 8)}...</span>
          <div class="flex items-center gap-1">
            <div class="indicator">
              <span class={[
                "indicator-item badge badge-xs",
                connection_status_badge_class(@connection_state)
              ]}>
              </span>
              <span>{connection_status_text(@connection_state)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private functions

  defp update_presence_state(socket) do
    # TODO: Integrate with Phoenix.Presence to get real presence data
    # For now, simulate with current user only

    active_users = %{
      socket.assigns.user.id => %{
        name: String.split(socket.assigns.user.email, "@") |> List.first() |> String.capitalize(),
        email: socket.assigns.user.email,
        status: :online,
        cursor_position: %{line: 1, column: 1},
        typing: false,
        # Blue color for current user
        color: "#3B82F6"
      }
    }

    assign(socket, :active_users, active_users)
  end

  # Template helper functions

  defp user_count(active_users) do
    map_size(active_users)
  end

  defp user_avatar_color(user_data) do
    case user_data[:color] do
      nil -> "bg-gray-500"
      color -> "bg-[#{color}]"
    end
  end

  defp user_avatar_text(user_data) do
    cond do
      user_data.name -> String.first(user_data.name) |> String.upcase()
      user_data.email -> String.first(user_data.email) |> String.upcase()
      true -> "U"
    end
  end

  defp user_status_badge_class(user_data) do
    case user_data[:status] do
      :online -> "badge-success"
      :away -> "badge-warning"
      :offline -> "badge-neutral"
      _ -> "badge-neutral"
    end
  end

  defp user_status_text(user_data) do
    case user_data[:status] do
      :online -> "Online"
      :away -> "Away"
      :offline -> "Offline"
      _ -> "Unknown"
    end
  end

  defp duck_status_badge_class(status) do
    case status do
      :available -> "badge-success"
      :busy -> "badge-warning"
      :offline -> "badge-neutral"
      _ -> "badge-neutral"
    end
  end

  defp duck_status_text(status) do
    case status do
      :available -> "Available"
      :busy -> "Processing"
      :offline -> "Offline"
      _ -> "Unknown"
    end
  end

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
      :disconnected -> "Offline"
      :error -> "Error"
      _ -> "Unknown"
    end
  end
end
