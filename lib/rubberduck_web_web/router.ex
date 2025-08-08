defmodule RubberduckWebWeb.Router do
  use RubberduckWebWeb, :router
  use AshAuthentication.Phoenix.Router
  
  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RubberduckWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
  end

  scope "/", RubberduckWebWeb do
    pipe_through :browser

    get "/", PageController, :home
    
    # Demo authentication routes
    post "/demo-login", PageController, :demo_login
    post "/demo-logout", PageController, :demo_logout
    
    # Authentication routes with DaisyUI overrides
    auth_routes AuthController, RubberduckWeb.Accounts.User, path: "/auth"
    sign_out_route AuthController
    
    # Sign in page with custom DaisyUI styling
    sign_in_route(
      overrides: [
        RubberduckWebWeb.Auth.DaisyUIOverrides, 
        AshAuthentication.Phoenix.Overrides.Default
      ],
      register_path: "/register",
      reset_path: "/password-reset"
    )
    
    # Protected routes
    live "/code", CollaborativeCodingLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", RubberduckWebWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rubberduck_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RubberduckWebWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
