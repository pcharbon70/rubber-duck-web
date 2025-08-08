defmodule RubberduckWebWeb.Components.RubberDuckSVG do
  @moduledoc """
  Reusable SVG component for the RubberDuck logo.
  Uses the assets/rubberduck.svg file content.
  """
  use Phoenix.Component

  @doc """
  Renders a rubber duck SVG at the specified size.

  ## Examples

      <.rubber_duck size="lg" />
      <.rubber_duck size="md" class="inline-block" />
      <.rubber_duck size="sm" />
      <.rubber_duck class="w-40 h-40" /> <!-- Custom size -->
  """
  attr :size, :string, default: "md"
  attr :class, :string, default: ""
  attr :rest, :global

  def rubber_duck(assigns) do
    size_class =
      case assigns.size do
        "lg" -> "w-32 h-32"
        "md" -> "w-20 h-20"
        "sm" -> "w-8 h-8"
        _ -> ""
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <img
      src="/images/rubberduck.svg"
      alt="RubberDuck Logo"
      class={[@size_class, @class]}
      {@rest}
    />
    """
  end
end
