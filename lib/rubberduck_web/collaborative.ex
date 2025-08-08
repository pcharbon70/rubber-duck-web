defmodule RubberduckWeb.Collaborative do
  @moduledoc """
  Domain module for collaborative coding features.
  
  Handles session management, real-time collaboration state,
  and coordination between users and the Duck LLM agent.
  """

  use Ash.Domain

  alias RubberduckWeb.Collaborative.Session

  resources do
    resource RubberduckWeb.Collaborative.Session
  end

  # Public API functions for session management

  @doc """
  Get a session by session_id.
  """
  def get_by_session_id(session_id) do
    Session
    |> Ash.Query.for_read(:get_by_session_id, %{session_id: session_id})
    |> Ash.read_one()
    |> case do
      {:ok, session} -> {:ok, session}
      {:error, _reason} -> {:ok, nil}
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Start a new collaborative session.
  """
  def start_session(params) do
    Session
    |> Ash.Changeset.for_create(:start_session, params)
    |> Ash.create()
  rescue
    error -> {:error, error}
  end

  @doc """
  Join an existing session.
  """
  def join_session(session, params) do
    # Add participant to existing session
    session
    |> Ash.Changeset.for_update(:add_participant, params)
    |> Ash.update()
  rescue
    error -> {:error, error}
  end

  @doc """
  Update session content (editor changes).
  """
  def update_session_content(session_id, content) do
    with {:ok, session} <- get_by_session_id(session_id),
         session when not is_nil(session) <- session do
      session
      |> Ash.Changeset.for_update(:update_content, %{editor_content: content})
      |> Ash.update()
    else
      {:ok, nil} -> {:error, "Session not found"}
      error -> error
    end
  end

  @doc """
  Add or update Duck context for the session.
  """
  def update_duck_context(session_id, context) do
    with {:ok, session} <- get_by_session_id(session_id),
         session when not is_nil(session) <- session do
      session
      |> Ash.Changeset.for_update(:update_duck_context, %{duck_context: context})
      |> Ash.update()
    else
      {:ok, nil} -> {:error, "Session not found"}
      error -> error
    end
  end

  @doc """
  Add a chat message to the session.
  """
  def add_chat_message(session_id, message_data) do
    with {:ok, session} <- get_by_session_id(session_id),
         session when not is_nil(session) <- session do
      
      # Add message to Duck context conversation history
      current_context = session.duck_context || %{}
      conversation_history = current_context["conversation_history"] || []
      
      new_message = %{
        id: generate_message_id(),
        content: message_data.content,
        sender_id: message_data.sender_id,
        sender_type: message_data.sender_type,
        timestamp: message_data.timestamp
      }
      
      updated_history = conversation_history ++ [new_message]
      # Keep only last 100 messages to manage memory
      updated_history = Enum.take(updated_history, -100)
      
      updated_context = Map.put(current_context, "conversation_history", updated_history)
      
      session
      |> Ash.Changeset.for_update(:update_duck_context, %{duck_context: updated_context})
      |> Ash.update()
    else
      {:ok, nil} -> {:error, "Session not found"}
      error -> error
    end
  end

  @doc """
  Get chat messages for a session.
  """
  def get_chat_messages(session_id) do
    with {:ok, session} <- get_by_session_id(session_id),
         session when not is_nil(session) <- session do
      
      conversation_history = 
        session.duck_context
        |> Map.get("conversation_history", [])
      
      {:ok, conversation_history}
    else
      {:ok, nil} -> {:ok, []}
      error -> error
    end
  end

  defp generate_message_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end