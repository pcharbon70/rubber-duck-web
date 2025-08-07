defmodule RubberduckWebWeb.CollaborativeCodingLive.EditorComponent do
  @moduledoc """
  LiveView component for Monaco Editor integration.
  
  Handles code editing with real-time collaboration features.
  """

  use RubberduckWebWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:editor_content, "")
      |> assign(:cursor_position, %{line: 1, column: 1})
      |> assign(:syntax_mode, "elixir")
      |> assign(:loading, true)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("editor_change", %{"content" => content}, socket) do
    # TODO: Implement editor change handling
    # TODO: Broadcast changes to other users
    
    socket = assign(socket, :editor_content, content)
    send(self(), {:editor_update, %{content: content, user_id: socket.assigns.user.id}})
    
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cursor_move", %{"position" => position}, socket) do
    # TODO: Broadcast cursor position to other users
    
    socket = assign(socket, :cursor_position, position)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="editor-container h-full bg-base-300 flex flex-col">
      
      <!-- Editor header -->
      <div class="navbar bg-base-200 min-h-0 px-4 py-2 border-b border-base-300">
        <div class="navbar-start">
          <div class="flex items-center gap-2">
            <span class="text-sm font-semibold text-base-content">💻 Code Editor</span>
            <div class="badge badge-primary badge-sm">
              <%= String.upcase(@syntax_mode) %>
            </div>
          </div>
        </div>
        
        <div class="navbar-end">
          <div class="flex items-center gap-2">
            <div class="badge badge-ghost badge-sm">
              Line <%= @cursor_position.line %>, Col <%= @cursor_position.column %>
            </div>
            
            <%= if @connection_state != :connected do %>
              <div class={[
                "badge badge-sm",
                connection_status_badge_class(@connection_state)
              ]}>
                <%= connection_status_text(@connection_state) %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Monaco Editor Container -->
      <div class="editor-content flex-1 relative bg-base-100" 
           phx-update="ignore"
           phx-hook="MonacoEditor"
           id={"monaco-editor-#{@id}"}
           data-language={@syntax_mode}
           data-theme="vs-dark">
        
        <!-- Loading state -->
        <%= if @loading do %>
          <div class="absolute inset-0 flex items-center justify-center bg-base-100">
            <div class="text-center">
              <span class="loading loading-spinner loading-lg text-primary mb-4"></span>
              <div class="text-base-content/60">Loading Editor...</div>
            </div>
          </div>
        <% end %>
        
        <!-- Fallback textarea for when Monaco fails to load -->
        <textarea class="textarea textarea-bordered absolute inset-0 w-full h-full font-mono text-sm resize-none"
                  style="font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace; display: none;"
                  id={"fallback-editor-#{@id}"}
                  phx-target={@myself}
                  phx-change="editor_change"
                  phx-debounce="250"
                  placeholder="Loading Monaco Editor..."><%= @editor_content %></textarea>
      </div>

      <!-- Editor footer with status info -->
      <div class="bg-base-200 px-4 py-1 border-t border-base-300">
        <div class="flex items-center justify-between text-xs text-base-content/60">
          <div class="flex items-center gap-4">
            <span>Session: <%= String.slice(@session_id, 0, 8) %>...</span>
            <span>Mode: <%= @layout %></span>
          </div>
          
          <div class="flex items-center gap-4">
            <!-- TODO: Add collaborative cursors info -->
            <div class="badge badge-success badge-xs">Ready</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

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