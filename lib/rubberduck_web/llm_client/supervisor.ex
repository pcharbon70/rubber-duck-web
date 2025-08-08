defmodule RubberduckWeb.LLMClient.Supervisor do
  @moduledoc """
  Supervises the LLM client processes that connect to the external Duck server.
  """

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Start the socket connection first
      {RubberduckWeb.LLMClient.Socket, []},
      # Then start the channel manager
      {RubberduckWeb.LLMClient.Channel, []}
    ]

    # Restart strategy: if one fails, restart both in order
    Supervisor.init(children, strategy: :rest_for_one)
  end
end