defmodule RubberduckWeb.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        RubberduckWeb.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:rubberduck_web, :token_signing_secret)
  end
end
