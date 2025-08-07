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
end