defmodule RubberduckWebWeb.PageController do
  use RubberduckWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  @doc """
  Demo login action with hardcoded credentials.
  Only accepts username: "rubberduck" and password: "rubberduck" as administrator.
  """
  def demo_login(conn, %{"username" => username, "password" => password}) do
    if username == "rubberduck" && password == "rubberduck" do
      # Create a demo user session
      demo_user = %{
        id: "demo_admin_user",
        email: "admin@rubberduck.local",
        username: "rubberduck",
        role: :administrator,
        is_demo: true
      }
      
      # Generate a simple session token (in production, use proper JWT)
      token = Base.encode64(:crypto.strong_rand_bytes(32))
      
      conn
      |> put_session(:user_token, token)
      |> put_session(:current_user, demo_user)
      |> put_flash(:info, "Welcome to RubberDuck, Administrator!")
      |> redirect(to: ~p"/code")
    else
      conn
      |> put_flash(:error, "Invalid credentials. Use 'rubberduck' for both username and password.")
      |> redirect(to: ~p"/")
    end
  end

  @doc """
  Demo logout action.
  Clears the demo session and redirects to home page.
  """
  def demo_logout(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "You have been logged out successfully.")
    |> redirect(to: ~p"/")
  end
end
