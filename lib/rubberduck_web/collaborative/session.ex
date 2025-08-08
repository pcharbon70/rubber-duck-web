defmodule RubberduckWeb.Collaborative.Session do
  @moduledoc """
  Ash resource for collaborative coding sessions.

  Tracks session state, participants, and collaborative data
  for real-time coding environments.
  """

  use Ash.Resource,
    otp_app: :rubberduck_web,
    domain: RubberduckWeb.Collaborative,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults [:create, :read, :update, :destroy]

    create :start_session do
      description "Create a new collaborative session"

      argument :creator_id, :string, allow_nil?: false
      argument :session_name, :string

      change set_attribute(:creator_id, arg(:creator_id))
      change set_attribute(:name, arg(:session_name))
      change set_attribute(:status, :active)
      change set_attribute(:created_at, &DateTime.utc_now/0)
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    update :join_session do
      description "Add a user to the session"
      require_atomic? false

      argument :user_id, :string, allow_nil?: false

      change fn changeset, _context ->
        current_participants = Ash.Changeset.get_attribute(changeset, :participants) || []

        new_participant = %{
          user_id: Ash.Changeset.get_argument(changeset, :user_id),
          joined_at: DateTime.utc_now(),
          status: :active,
          role: :collaborator
        }

        updated_participants = [new_participant | current_participants]

        changeset
        |> Ash.Changeset.change_attribute(:participants, updated_participants)
        |> Ash.Changeset.change_attribute(:updated_at, DateTime.utc_now())
      end
    end

    update :leave_session do
      description "Remove a user from the session"
      require_atomic? false

      argument :user_id, :string, allow_nil?: false

      change fn changeset, _context ->
        user_id = Ash.Changeset.get_argument(changeset, :user_id)
        current_participants = Ash.Changeset.get_attribute(changeset, :participants) || []

        updated_participants =
          Enum.map(current_participants, fn participant ->
            if participant.user_id == user_id do
              %{participant | status: :left, left_at: DateTime.utc_now()}
            else
              participant
            end
          end)

        changeset
        |> Ash.Changeset.change_attribute(:participants, updated_participants)
        |> Ash.Changeset.change_attribute(:updated_at, DateTime.utc_now())
      end
    end

    update :update_editor_content do
      description "Update the shared editor content"
      require_atomic? false

      argument :content, :string, allow_nil?: false
      argument :updated_by, :string, allow_nil?: false

      change set_attribute(:editor_content, arg(:content))

      change fn changeset, _context ->
        content_history = Ash.Changeset.get_attribute(changeset, :content_history) || []

        new_history_entry = %{
          content: Ash.Changeset.get_argument(changeset, :content),
          updated_by: Ash.Changeset.get_argument(changeset, :updated_by),
          updated_at: DateTime.utc_now()
        }

        # Keep last 50 content history entries
        updated_history =
          [new_history_entry | content_history]
          |> Enum.take(50)

        changeset
        |> Ash.Changeset.change_attribute(:content_history, updated_history)
        |> Ash.Changeset.change_attribute(:updated_at, DateTime.utc_now())
      end
    end

    update :end_session do
      description "Mark session as ended"

      change set_attribute(:status, :ended)
      change set_attribute(:ended_at, &DateTime.utc_now/0)
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    read :get_by_session_id do
      description "Get session by session_id"
      get? true

      argument :session_id, :string, allow_nil?: false
      filter expr(session_id == ^arg(:session_id))
    end

    read :active_sessions do
      description "Get all active sessions"
      filter expr(status == :active)
    end

    read :user_sessions do
      description "Get sessions for a user"

      argument :user_id, :string, allow_nil?: false

      filter expr(creator_id == ^arg(:user_id))
    end

    update :add_participant do
      description "Add participant to existing session"
      require_atomic? false

      argument :user_id, :string, allow_nil?: false

      change fn changeset, _context ->
        current_participants = Ash.Changeset.get_attribute(changeset, :participants) || []

        new_participant = %{
          user_id: Ash.Changeset.get_argument(changeset, :user_id),
          joined_at: DateTime.utc_now(),
          status: :active,
          role: :collaborator
        }

        updated_participants = [new_participant | current_participants]

        changeset
        |> Ash.Changeset.change_attribute(:participants, updated_participants)
        |> Ash.Changeset.change_attribute(:updated_at, DateTime.utc_now())
      end
    end

    update :update_content do
      description "Update session content"
      require_atomic? false

      argument :editor_content, :string, allow_nil?: false

      change set_attribute(:editor_content, arg(:editor_content))
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    update :update_duck_context do
      description "Update Duck context"
      require_atomic? false

      argument :duck_context, :map, allow_nil?: false

      change set_attribute(:duck_context, arg(:duck_context))
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end
  end

  validations do
    validate present(:session_id)
    validate present(:creator_id)
  end

  attributes do
    uuid_primary_key :id

    attribute :session_id, :string do
      description "Unique session identifier"
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      description "Human-readable session name"
      public? true
    end

    attribute :creator_id, :string do
      description "User ID of session creator"
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      description "Session status"
      constraints one_of: [:active, :paused, :ended]
      default :active
      public? true
    end

    attribute :participants, {:array, :map} do
      description "List of session participants with metadata"
      default []
      public? true
    end

    attribute :editor_content, :string do
      description "Current shared editor content"
      default ""
      public? true
    end

    attribute :editor_language, :string do
      description "Programming language for syntax highlighting"
      default "elixir"
      public? true
    end

    attribute :content_history, {:array, :map} do
      description "History of content changes for collaboration"
      default []
      public? true
    end

    attribute :layout_config, :map do
      description "Shared layout configuration"

      default %{
        editor_width_percent: 70,
        chat_width_percent: 30,
        theme: :dark
      }

      public? true
    end

    attribute :duck_context, :map do
      description "Context data for Duck LLM agent interactions"

      default %{
        conversation_history: [],
        code_analysis_cache: %{},
        last_interaction: nil
      }

      public? true
    end

    attribute :metadata, :map do
      description "Additional session metadata"
      default %{}
      public? true
    end

    create_timestamp :created_at, public?: true
    update_timestamp :updated_at, public?: true

    attribute :ended_at, :utc_datetime_usec do
      description "When the session was ended"
      public? true
    end
  end

  relationships do
    # Note: We can't directly relate to User resource from different domain
    # Instead we store user_id strings and resolve separately
  end

  calculations do
    calculate :active_participants_count, :integer do
      calculation fn records, _context ->
        Enum.map(records, fn session ->
          session.participants
          |> Enum.count(fn participant -> participant[:status] == "active" end)
        end)
      end
    end

    calculate :is_creator, :boolean do
      argument :user_id, :string, allow_nil?: false
      calculation expr(creator_id == ^arg(:user_id))
    end

    calculate :user_role, :string do
      argument :user_id, :string, allow_nil?: false

      calculation fn records, context ->
        user_id = context.arguments.user_id

        Enum.map(records, fn session ->
          cond do
            session.creator_id == user_id ->
              "creator"

            participant = Enum.find(session.participants, &(&1.user_id == user_id)) ->
              participant[:role] || "collaborator"

            true ->
              "guest"
          end
        end)
      end
    end
  end

  identities do
    identity :unique_session_id, [:session_id] do
      pre_check_with RubberduckWeb.Collaborative
    end
  end
end
