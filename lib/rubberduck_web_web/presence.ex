defmodule RubberduckWebWeb.Presence do
  @moduledoc """
  Presence tracking for collaborative sessions.
  """
  
  use Phoenix.Presence,
    otp_app: :rubberduck_web,
    pubsub_server: RubberduckWeb.PubSub
end