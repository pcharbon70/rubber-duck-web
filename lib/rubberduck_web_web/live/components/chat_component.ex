defmodule RubberduckWebWeb.CollaborativeCodingLive.ChatComponent do
  @moduledoc """
  LiveView component for LLM chat interaction.
  
  Handles user ↔ Duck (LLM agent) communication with real-time messaging.
  """

  use RubberduckWebWeb, :live_component

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:messages, [])
      |> assign(:message_input, "")
      |> assign(:typing_state, false)
      |> assign(:duck_typing, false)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_add_welcome_message()

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) when content != "" do
    message = create_user_message(content, socket.assigns.user)
    
    socket =
      socket
      |> add_message(message)
      |> assign(:message_input, "")
      |> assign(:loading, true)

    # Send message to Duck agent via parent LiveView
    send(self(), {:chat_message, %{content: content, user_id: socket.assigns.user.id, session_id: socket.assigns.session_id}})
    
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("send_message", _params, socket) do
    # Handle empty message case
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("message_input_change", %{"message" => %{"content" => content}}, socket) do
    socket =
      socket
      |> assign(:message_input, content)
      |> assign(:typing_state, String.length(content) > 0)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear_chat", _params, socket) do
    socket =
      socket
      |> assign(:messages, [])
      |> maybe_add_welcome_message()

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="chat-container h-full bg-base-100 flex flex-col">
      
      <!-- Chat header -->
      <div class="chat-header flex-none bg-base-200 px-4 py-3 border-b border-base-300">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="avatar placeholder">
              <div class="bg-warning text-warning-content w-8 rounded-full">
                <span class="text-sm">🦆</span>
              </div>
            </div>
            <div>
              <h3 class="font-semibold text-base-content">Duck Assistant</h3>
              <p class="text-xs text-base-content/60">
                <%= duck_status_text(@duck_agent.status) %>
              </p>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <%= if @connection_state != :connected do %>
              <div class="badge badge-warning badge-sm">
                <%= connection_status_text(@connection_state) %>
              </div>
            <% end %>
            
            <button phx-click="clear_chat" 
                    phx-target={@myself}
                    class="btn btn-ghost btn-xs"
                    title="Clear chat">
              🗑️ Clear
            </button>
          </div>
        </div>
      </div>

      <!-- Messages container -->
      <div class="messages-container flex-1 overflow-y-auto p-4" 
           id={"messages-#{@id}"}>
        <%= for message <- @messages do %>
          <div class={daisyui_chat_class(message.sender_type)}>
            <div class="chat-image avatar">
              <div class="w-8 rounded-full bg-base-300 flex items-center justify-center">
                <%= message_avatar(message.sender_type) %>
              </div>
            </div>
            <div class="chat-header text-xs opacity-50">
              <%= message.sender_name %>
              <time class="ml-1"><%= format_timestamp(message.timestamp) %></time>
            </div>
            
            <div class={daisyui_chat_bubble_class(message.sender_type)}>
              <%= if message.content_type == :code do %>
                <!-- Code block in mockup component -->
                <div class="mockup-code text-xs my-2">
                  <pre><code><%= message.content %></code></pre>
                </div>
                
                <!-- Code actions -->
                <div class="flex gap-2 mt-2">
                  <button class="btn btn-primary btn-xs">
                    📋 Apply to Editor
                  </button>
                  <button class="btn btn-ghost btn-xs">
                    📄 Copy
                  </button>
                </div>
              <% else %>
                <!-- Regular text content -->
                <div class="prose prose-sm max-w-none">
                  <%= format_message_content(message.content) %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <!-- Duck typing indicator -->
        <%= if @duck_typing do %>
          <div class="chat chat-start">
            <div class="chat-image avatar">
              <div class="w-8 rounded-full bg-warning text-warning-content flex items-center justify-center">
                🦆
              </div>
            </div>
            <div class="chat-bubble chat-bubble-accent">
              <div class="flex items-center gap-2">
                <span class="loading loading-dots loading-sm"></span>
                <span class="text-xs">Duck is thinking...</span>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Message input -->
      <div class="message-input flex-none border-t border-base-300 p-4">
        <form phx-submit="send_message" phx-target={@myself} class="join w-full">
          <textarea name="message[content]"
                    value={@message_input}
                    phx-change="message_input_change"
                    phx-target={@myself}
                    phx-debounce="300"
                    rows="1"
                    class="textarea textarea-bordered join-item flex-1 resize-none"
                    placeholder="Ask Duck for help with your code... 🦆"
                    disabled={@connection_state != :connected}></textarea>
          
          <button type="submit"
                  class={[
                    "btn join-item",
                    if(@loading, do: "btn-disabled", else: "btn-primary")
                  ]}
                  disabled={@connection_state != :connected or @loading or String.trim(@message_input) == ""}>
            <%= if @loading do %>
              <span class="loading loading-spinner loading-sm"></span>
            <% else %>
              📤 Send
            <% end %>
          </button>
        </form>

        <!-- Connection status message -->
        <%= if @connection_state != :connected do %>
          <div class="alert alert-warning mt-2">
            <span class="text-xs">⚠️ <%= connection_help_text(@connection_state) %></span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Private functions

  defp maybe_add_welcome_message(socket) do
    if Enum.empty?(socket.assigns.messages) do
      welcome_message = create_duck_message(
        "Hello! I'm Duck, your AI coding assistant. I can help you with code analysis, suggestions, explanations, and more. How can I assist you today?",
        socket.assigns.duck_agent
      )
      add_message(socket, welcome_message)
    else
      socket
    end
  end

  defp create_user_message(content, user) do
    %{
      id: generate_message_id(),
      content: content,
      content_type: :text,
      sender_type: :user,
      sender_name: user.email,
      sender_id: user.id,
      timestamp: DateTime.utc_now()
    }
  end

  defp create_duck_message(content, duck_agent) do
    %{
      id: generate_message_id(),
      content: content,
      content_type: :text,
      sender_type: :duck,
      sender_name: duck_agent.name,
      sender_id: duck_agent.id,
      timestamp: DateTime.utc_now()
    }
  end

  defp add_message(socket, message) do
    messages = socket.assigns.messages ++ [message]
    assign(socket, :messages, messages)
  end

  defp generate_message_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  # Template helper functions

  defp duck_status_text(status) do
    case status do
      :available -> "Available"
      :busy -> "Processing..."
      :offline -> "Offline"
      _ -> "Unknown"
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

  defp connection_help_text(state) do
    case state do
      :connecting -> "Connecting to Duck..."
      :disconnected -> "Connection lost. Messages will be queued until reconnected."
      :error -> "Connection error. Please check your network."
      _ -> ""
    end
  end

  defp daisyui_chat_class(sender_type) do
    case sender_type do
      :user -> "chat chat-end"
      :duck -> "chat chat-start"
      _ -> "chat chat-start"
    end
  end

  defp daisyui_chat_bubble_class(sender_type) do
    case sender_type do
      :user -> "chat-bubble chat-bubble-primary"
      :duck -> "chat-bubble chat-bubble-secondary"
      _ -> "chat-bubble"
    end
  end

  defp message_avatar(sender_type) do
    case sender_type do
      :user -> "U"
      :duck -> "🦆"
      _ -> "?"
    end
  end

  defp format_timestamp(timestamp) do
    timestamp
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 5)  # HH:MM format
  end

  defp format_message_content(content) do
    # Simple line break handling - could be enhanced with markdown parsing
    content
    |> String.replace("\n", "<br>")
    |> Phoenix.HTML.raw()
  end
end