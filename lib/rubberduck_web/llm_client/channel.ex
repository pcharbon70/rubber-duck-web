defmodule RubberduckWeb.LLMClient.Channel do
  @moduledoc """
  Manages the Phoenix Channel connection to the Duck LLM server.
  Handles message routing between our server and the external LLM server.
  """

  use GenServer
  require Logger

  alias PhoenixClient.{Channel, Message}
  alias RubberduckWeb.LLMClient.Socket

  @default_channel_topic "llm:chat"
  @join_timeout 10_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def send_message(conversation_id, message) do
    GenServer.cast(__MODULE__, {:send_message, conversation_id, message})
  end

  def request_completion(conversation_id, prompt, callback_pid) do
    GenServer.call(__MODULE__, {:request_completion, conversation_id, prompt, callback_pid})
  end

  def joined? do
    GenServer.call(__MODULE__, :joined?)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    config = Application.get_env(:rubberduck_web, :llm_server, [])
    
    state = %{
      channel_topic: Keyword.get(config, :channel_topic, @default_channel_topic),
      channel: nil,
      joined: false,
      pending_requests: %{},
      conversation_callbacks: %{}
    }

    # Start joining process after socket is ready
    Process.send_after(self(), :join_channel, 1_000)
    
    {:ok, state}
  end

  @impl true
  def handle_info(:join_channel, state) do
    case Socket.socket() do
      nil ->
        # Socket not ready, retry
        Process.send_after(self(), :join_channel, 2_000)
        {:noreply, state}
      
      socket ->
        join_channel(socket, state)
    end
  end

  @impl true
  def handle_info({:channel_closed, _reason}, state) do
    Logger.warning("LLM channel closed, attempting to rejoin...")
    Process.send_after(self(), :join_channel, 2_000)
    {:noreply, %{state | channel: nil, joined: false}}
  end

  # Handle messages from Phoenix Client Channel
  @impl true
  def handle_info(%Message{event: "completion:chunk", payload: payload}, state) do
    # Forward streaming chunk to the appropriate callback
    conversation_id = payload["conversation_id"]
    chunk = payload["chunk"]
    
    case Map.get(state.conversation_callbacks, conversation_id) do
      nil ->
        Logger.warning("Received LLM chunk for unknown conversation: #{conversation_id}")
      
      callback_pid ->
        send(callback_pid, {:llm_response_chunk, conversation_id, chunk})
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info(%Message{event: "completion:response", payload: payload}, state) do
    # Forward complete response to the appropriate callback
    conversation_id = payload["conversation_id"]
    response = payload["response"]
    
    case Map.get(state.conversation_callbacks, conversation_id) do
      nil ->
        Logger.warning("Received LLM response for unknown conversation: #{conversation_id}")
      
      callback_pid ->
        send(callback_pid, {:llm_response, conversation_id, response})
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info(%Message{event: "completion:done", payload: payload}, state) do
    # Signal completion and clean up callback
    conversation_id = payload["conversation_id"]
    
    case Map.get(state.conversation_callbacks, conversation_id) do
      nil ->
        :ok
      
      callback_pid ->
        send(callback_pid, {:llm_response_complete, conversation_id})
    end
    
    new_callbacks = Map.delete(state.conversation_callbacks, conversation_id)
    {:noreply, %{state | conversation_callbacks: new_callbacks}}
  end

  @impl true
  def handle_info(%Message{event: "completion:error", payload: payload}, state) do
    Logger.error("LLM server error: #{inspect(payload)}")
    conversation_id = payload["conversation_id"]
    
    case Map.get(state.conversation_callbacks, conversation_id) do
      nil ->
        :ok
      
      callback_pid ->
        send(callback_pid, {:llm_response_complete, conversation_id})
    end
    
    new_callbacks = Map.delete(state.conversation_callbacks, conversation_id)
    {:noreply, %{state | conversation_callbacks: new_callbacks}}
  end

  # Catch-all for other Phoenix Client messages
  @impl true
  def handle_info(%Message{} = msg, state) do
    Logger.debug("Received unhandled message from LLM server: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(:joined?, _from, state) do
    {:reply, state.joined, state}
  end

  @impl true
  def handle_call({:request_completion, conversation_id, prompt, callback_pid}, _from, state) do
    if state.joined do
      # Register callback for this conversation
      new_callbacks = Map.put(state.conversation_callbacks, conversation_id, callback_pid)
      
      # Send message to LLM server
      message = %{
        conversation_id: conversation_id,
        prompt: prompt,
        stream: true
      }
      
      case Channel.push(state.channel, "completion:request", message) do
        {:ok, _ref} ->
          {:reply, :ok, %{state | conversation_callbacks: new_callbacks}}
        
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :not_connected}, state}
    end
  end

  @impl true
  def handle_cast({:send_message, conversation_id, message}, state) do
    if state.joined do
      payload = %{
        conversation_id: conversation_id,
        message: message
      }
      
      case Channel.push_async(state.channel, "message:new", payload) do
        :ok ->
          Logger.debug("Sent message to LLM server for conversation #{conversation_id}")
      end
    else
      Logger.warning("Cannot send message, not connected to LLM server")
    end
    
    {:noreply, state}
  end

  # Private functions

  defp join_channel(socket, state) do
    Logger.info("Attempting to join LLM channel: #{state.channel_topic}")
    
    case Channel.join(socket, state.channel_topic, %{}, @join_timeout) do
      {:ok, _response, channel} ->
        Logger.info("Successfully joined LLM channel")
        
        # The channel will send messages directly to this process
        # No need to set up separate handlers
        
        {:noreply, %{state | channel: channel, joined: true}}
      
      {:error, reason} ->
        Logger.error("Failed to join LLM channel: #{inspect(reason)}")
        Process.send_after(self(), :join_channel, 5_000)
        {:noreply, state}
    end
  end
end