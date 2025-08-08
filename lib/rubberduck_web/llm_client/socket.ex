defmodule RubberduckWeb.LLMClient.Socket do
  @moduledoc """
  Manages the WebSocket connection to the external Duck LLM server using Phoenix Client.
  """

  use GenServer
  require Logger

  alias PhoenixClient.Socket

  @reconnect_interval 5_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def connected? do
    GenServer.call(__MODULE__, :connected?)
  end

  def socket do
    GenServer.call(__MODULE__, :get_socket)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Get configuration from runtime config
    config = Application.get_env(:rubberduck_web, :llm_server, [])
    
    state = %{
      url: Keyword.get(config, :url, "ws://localhost:4000/socket/websocket"),
      api_key: Keyword.get(config, :api_key),
      socket: nil,
      connected: false
    }

    # Start connection process
    send(self(), :connect)
    
    {:ok, state}
  end

  @impl true
  def handle_info(:connect, state) do
    Logger.info("Attempting to connect to Duck LLM server at #{state.url}")
    
    socket_opts = build_socket_opts(state)
    
    case Socket.start_link(socket_opts) do
      {:ok, socket} ->
        Logger.info("Successfully connected to Duck LLM server")
        {:noreply, %{state | socket: socket, connected: true}}
      
      {:error, reason} ->
        Logger.error("Failed to connect to Duck LLM server: #{inspect(reason)}")
        # Retry connection after interval
        Process.send_after(self(), :connect, @reconnect_interval)
        {:noreply, %{state | connected: false}}
    end
  end

  @impl true
  def handle_info({:socket_closed, _reason}, state) do
    Logger.warning("Connection to Duck LLM server closed, attempting reconnect...")
    send(self(), :connect)
    {:noreply, %{state | socket: nil, connected: false}}
  end

  @impl true
  def handle_call(:connected?, _from, state) do
    {:reply, state.connected, state}
  end

  @impl true
  def handle_call(:get_socket, _from, state) do
    {:reply, state.socket, state}
  end

  # Private functions

  defp build_socket_opts(state) do
    base_opts = [
      url: state.url,
      reconnect_interval: @reconnect_interval,
      heartbeat_interval: 30_000,
      logger: &logger/2
    ]

    # Add authentication params if API key is present
    if state.api_key do
      Keyword.put(base_opts, :params, %{api_key: state.api_key})
    else
      base_opts
    end
  end

  defp logger(:connect, _opts), do: :ok
  defp logger(:disconnect, _opts), do: :ok
  defp logger(level, message) do
    Logger.debug("[LLM Socket] #{level}: #{inspect(message)}")
  end
end