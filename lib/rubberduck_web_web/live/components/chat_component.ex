defmodule RubberduckWebWeb.CollaborativeCodingLive.ChatComponent do
  @moduledoc """
  LiveView component for LLM chat interaction.
  
  Handles user ↔ Duck (LLM agent) communication with real-time messaging.
  """

  use RubberduckWebWeb, :live_component
  
  import RubberduckWebWeb.Components.UserAvatar

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> assign(:messages, [])
      |> assign(:system_messages, [])
      |> assign(:message_input, "")
      |> assign(:typing_state, false)
      |> assign(:duck_typing, false)
      |> assign(:loading, false)
      |> assign(:active_users, %{})

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_handle_new_system_message(assigns)
      |> maybe_handle_new_message(assigns)
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
  def handle_event("add_system_message", %{"content" => content}, socket) do
    system_message = create_system_message(content)
    
    socket =
      socket
      |> add_system_message(system_message)

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("clear_system_messages", _params, socket) do
    socket = assign(socket, :system_messages, [])
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
                <img src="/images/rubberduck.svg" alt="Duck" class="w-4 h-4" />
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

      <!-- Main chat area with users sidebar -->
      <div class="chat-main flex-1 flex min-h-0">
        <!-- Chat content (left side) -->
        <div class="chat-content flex-1 flex flex-col min-h-0">
        
        <!-- System Broadcast Area (Top 20%) -->
        <div class="system-broadcast-area flex-none bg-base-50 border-b border-base-300"
             style="height: 20%; min-height: 120px;">
          <div class="h-full flex flex-col">
            <!-- System broadcast header -->
            <div class="flex-none px-3 py-2 bg-info/10 border-b border-info/20">
              <div class="flex items-center gap-2">
                <div class="indicator">
                  <span class="indicator-item badge badge-info badge-xs"></span>
                  <span class="text-xs font-medium text-info">🔔 Server Status</span>
                </div>
              </div>
            </div>
            
            <!-- System messages -->
            <div class="flex-1 overflow-y-auto p-2 space-y-1">
              <%= for system_message <- @system_messages do %>
                <div class="alert alert-info alert-sm py-1">
                  <div class="flex items-center gap-2 text-xs">
                    <span class="opacity-60"><%= format_timestamp(system_message.timestamp) %></span>
                    <span><%= system_message.content %></span>
                  </div>
                </div>
              <% end %>
              
              <!-- Default system message if empty -->
              <%= if Enum.empty?(@system_messages) do %>
                <div class="text-xs text-base-content/40 text-center py-4">
                  System notifications will appear here
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Conversation Area (Bottom 80%) -->
        <div class="conversation-area flex-1 flex flex-col min-h-0">
          <!-- Conversation messages -->
          <div class="conversation-messages flex-1 overflow-y-auto p-4" 
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
                    <img src="/images/rubberduck.svg" alt="Duck" class="w-3 h-3 inline-block" />
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
                        placeholder="Ask Duck for help with your code..."
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
      </div>
      
      <!-- Users sidebar (right side) -->
      <div class="users-sidebar flex-none w-20 bg-base-200 border-l border-base-300 p-2">
        <div class="flex flex-col gap-3">
          <!-- Duck Assistant -->
          <.user_avatar 
            user={@duck_agent}
            is_duck={true}
            show_name={true}
            show_status={true}
            size="md"
          />
          
          <!-- Active Users -->
          <%= for {_user_id, user_data} <- @active_users || %{} do %>
            <.user_avatar 
              user={user_data}
              show_name={true}
              show_status={true}
              size="md"
            />
          <% end %>
        </div>
      </div>
    </div>
    </div>
    """
  end

  # Private functions

  defp maybe_add_welcome_message(socket) do
    socket = if Enum.empty?(socket.assigns.messages) do
      welcome_message = create_duck_message(
        "Hello! I'm Duck, your AI coding assistant. I can help you with code analysis, suggestions, explanations, and more. How can I assist you today?",
        socket.assigns.duck_agent
      )
      add_message(socket, welcome_message)
    else
      socket
    end

    # Add initial system messages if empty
    if Enum.empty?(socket.assigns.system_messages) do
      initial_system_messages = [
        create_system_message("Session initialized successfully"),
        create_system_message("Duck coding assistant online"),
        create_system_message("Waiting for server connection...")
      ]
      
      Enum.reduce(initial_system_messages, socket, fn system_message, acc ->
        add_system_message(acc, system_message)
      end)
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

  defp add_system_message(socket, system_message) do
    system_messages = socket.assigns.system_messages ++ [system_message]
    # Keep only last 20 system messages to prevent memory growth
    system_messages = Enum.take(system_messages, -20)
    assign(socket, :system_messages, system_messages)
  end

  defp create_system_message(content) do
    %{
      id: generate_message_id(),
      content: content,
      type: :system_broadcast,
      timestamp: DateTime.utc_now()
    }
  end

  defp maybe_handle_new_system_message(socket, %{system_message: system_message}) do
    add_system_message(socket, system_message)
  end
  defp maybe_handle_new_system_message(socket, _assigns), do: socket

  defp maybe_handle_new_message(socket, %{new_message: new_message}) do
    # Convert channel message format to component message format
    message = %{
      id: generate_message_id(),
      content: new_message.content,
      content_type: :text,
      sender_type: new_message.sender_type,
      sender_name: get_sender_name(new_message.sender_type, new_message.sender_id),
      sender_id: new_message.sender_id,
      timestamp: new_message.timestamp
    }
    add_message(socket, message)
  end
  defp maybe_handle_new_message(socket, _assigns), do: socket

  defp get_sender_name(:user, sender_id) do
    # In a real app, you might lookup user name by ID
    # For now, just use the sender_id
    "User"
  end
  defp get_sender_name(:duck, _sender_id), do: "Duck"
  defp get_sender_name(_, _sender_id), do: "Unknown"

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
      :duck -> "D"
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