defmodule RubberduckWeb.Accounts do
  @moduledoc """
  Accounts domain for user management and authentication.
  """

  use Ash.Domain, otp_app: :rubberduck_web, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource RubberduckWeb.Accounts.Token
    resource RubberduckWeb.Accounts.User
    resource RubberduckWeb.Accounts.ApiKey
  end
end
