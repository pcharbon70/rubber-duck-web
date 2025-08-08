defmodule RubberduckWebWeb.Components.UserAvatar do
  @moduledoc """
  Reusable user avatar component for displaying user presence.
  """
  use Phoenix.Component

  @doc """
  Renders a user avatar with optional description below.
  
  ## Examples
  
      <.user_avatar user={user} size="md" show_name={true} />
      <.user_avatar user={user} size="sm" show_status={true} />
  """
  attr :user, :map, required: true
  attr :size, :string, default: "md"
  attr :show_name, :boolean, default: true
  attr :show_status, :boolean, default: false
  attr :is_duck, :boolean, default: false
  attr :class, :string, default: ""

  def user_avatar(assigns) do
    size_classes = case assigns.size do
      "lg" -> "w-12 h-12 text-lg"
      "md" -> "w-10 h-10 text-base"
      "sm" -> "w-8 h-8 text-sm"
      _ -> "w-10 h-10 text-base"
    end
    
    assigns = assign(assigns, :size_classes, size_classes)
    
    ~H"""
    <div class={["flex flex-col items-center gap-1", @class]}>
      <!-- Avatar -->
      <div class="avatar placeholder relative">
        <div class={[
          "rounded-full flex items-center justify-center",
          @size_classes,
          if(@is_duck, do: "bg-warning", else: user_bg_color(@user))
        ]}>
          <%= if @is_duck do %>
            <img src="/images/rubberduck.svg" alt="Duck" class="w-5 h-5" />
          <% else %>
            <span class="font-medium text-base-100">
              <%= user_initials(@user) %>
            </span>
          <% end %>
        </div>
        
        <!-- Status indicator -->
        <%= if @show_status do %>
          <span class={[
            "absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-base-100",
            status_color(@user[:status] || :offline)
          ]}></span>
        <% end %>
      </div>
      
      <!-- Name/Description -->
      <%= if @show_name do %>
        <div class="text-center max-w-[60px]">
          <p class="text-xs text-base-content truncate">
            <%= user_display_name(@user) %>
          </p>
          <%= if @show_status && @user[:status] do %>
            <p class="text-[10px] text-base-content/60">
              <%= status_text(@user[:status]) %>
            </p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions
  
  defp user_initials(user) do
    cond do
      user[:username] -> 
        String.slice(user.username, 0, 2) |> String.upcase()
      user[:name] -> 
        user.name
        |> String.split(" ")
        |> Enum.map(&String.first/1)
        |> Enum.take(2)
        |> Enum.join()
        |> String.upcase()
      user[:email] -> 
        String.first(user.email) |> String.upcase()
      true -> 
        "U"
    end
  end

  defp user_display_name(user) do
    cond do
      user[:name] -> user.name
      user[:username] -> user.username
      user[:email] -> 
        user.email
        |> String.split("@")
        |> List.first()
        |> String.split(".")
        |> Enum.map(&String.capitalize/1)
        |> Enum.join(" ")
      true -> "User"
    end
  end

  defp user_bg_color(user) do
    # Generate consistent color based on user ID or use provided color
    if user[:color] do
      "bg-[#{user.color}]"
    else
      colors = [
        "bg-primary",
        "bg-secondary", 
        "bg-accent",
        "bg-info",
        "bg-success",
        "bg-warning",
        "bg-error"
      ]
      
      # Use user ID to consistently assign same color
      hash = :erlang.phash2(user[:id] || user[:email] || "default")
      index = rem(hash, length(colors))
      Enum.at(colors, index)
    end
  end

  defp status_color(status) do
    case status do
      :online -> "bg-success"
      :away -> "bg-warning"
      :busy -> "bg-error"
      _ -> "bg-base-300"
    end
  end

  defp status_text(status) do
    case status do
      :online -> "Online"
      :away -> "Away"
      :busy -> "Busy"
      _ -> "Offline"
    end
  end
end