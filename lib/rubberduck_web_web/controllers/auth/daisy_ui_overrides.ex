defmodule RubberduckWebWeb.Auth.DaisyUIOverrides do
  @moduledoc """
  DaisyUI theme overrides for ash_authentication_phoenix components.

  Customizes the default authentication components to use DaisyUI classes
  instead of the default Tailwind classes.
  """

  use AshAuthentication.Phoenix.Overrides

  # Override the main sign-in component
  override AshAuthentication.Phoenix.Components.SignIn do
    set(
      :root_class,
      "min-h-screen bg-base-200 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8"
    )

    set(:sign_in_id, "sign-in-form")
  end

  # Override the banner component with DaisyUI styling
  override AshAuthentication.Phoenix.Components.Banner do
    set(:root_class, "text-center mb-8")
    set(:href_class, "link link-hover")
    set(:image_class, "mx-auto h-24 w-auto")
    set(:text_class, "mt-6 text-3xl font-bold text-base-content")
    set(:image_url, "/images/rubberduck.svg")
    set(:text, "RubberDuck")
  end

  # Override the password component wrapper
  override AshAuthentication.Phoenix.Components.Password do
    set(:root_class, "w-full max-w-md")
    set(:toggler_class, "tabs tabs-boxed mb-6")
    set(:toggler_active_class, "tab tab-active")
    set(:toggler_inactive_class, "tab")
  end

  # Override the sign-in form with DaisyUI classes
  override AshAuthentication.Phoenix.Components.Password.SignInForm do
    set(:root_class, "card bg-base-100 shadow-xl")
    set(:form_class, "card-body")
    set(:header_class, "card-title text-2xl font-bold text-center mb-4")
    set(:header_text, "Sign in to your account")

    # Field styling
    set(:field_class, "form-control w-full")
    set(:label_class, "label")
    set(:input_class, "input input-bordered w-full")
    set(:error_field_class, "input input-bordered input-error w-full")

    # Submit button
    set(:submit_class, "btn btn-primary w-full mt-6")
    set(:submit_text, "Sign In")

    # Error styling
    set(:error_ul, "alert alert-error mt-4")
    set(:error_li, "text-sm")

    # Alternative actions
    set(:alternative_class, "mt-4 text-center")
    set(:toggle_class, "link link-primary text-sm")
    set(:reset_link_class, "link link-secondary text-sm ml-2")
  end

  # Override the registration form with DaisyUI classes
  override AshAuthentication.Phoenix.Components.Password.RegisterForm do
    set(:root_class, "card bg-base-100 shadow-xl")
    set(:form_class, "card-body")
    set(:header_class, "card-title text-2xl font-bold text-center mb-4")
    set(:header_text, "Create your account")

    # Field styling
    set(:field_class, "form-control w-full")
    set(:label_class, "label")
    set(:input_class, "input input-bordered w-full")
    set(:error_field_class, "input input-bordered input-error w-full")

    # Submit button
    set(:submit_class, "btn btn-primary w-full mt-6")
    set(:submit_text, "Create Account")

    # Error styling
    set(:error_ul, "alert alert-error mt-4")
    set(:error_li, "text-sm")

    # Alternative actions
    set(:alternative_class, "mt-4 text-center")
    set(:toggle_class, "link link-primary text-sm")
  end

  # Override the reset password form with DaisyUI classes
  override AshAuthentication.Phoenix.Components.Password.ResetForm do
    set(:root_class, "card bg-base-100 shadow-xl")
    set(:form_class, "card-body")
    set(:header_class, "card-title text-2xl font-bold text-center mb-4")
    set(:header_text, "Reset your password")

    # Field styling
    set(:field_class, "form-control w-full")
    set(:label_class, "label")
    set(:input_class, "input input-bordered w-full")
    set(:error_field_class, "input input-bordered input-error w-full")

    # Submit button
    set(:submit_class, "btn btn-primary w-full mt-6")
    set(:submit_text, "Send Reset Instructions")

    # Error styling
    set(:error_ul, "alert alert-error mt-4")
    set(:error_li, "text-sm")

    # Alternative actions
    set(:alternative_class, "mt-4 text-center")
    set(:toggle_class, "link link-primary text-sm")
  end

  # Override OAuth/Magic Link components if needed
  override AshAuthentication.Phoenix.Components.MagicLink do
    set(:root_class, "mt-6")
    set(:request_button_class, "btn btn-outline btn-secondary w-full")
  end

  # Override form input component
  override AshAuthentication.Phoenix.Components.Input do
    set(:field_class, "form-control w-full mb-4")
    set(:label_class, "label label-text")
    set(:input_class, "input input-bordered w-full")
    set(:error_field_class, "input input-bordered input-error w-full")
    set(:error_ul, "label")
    set(:error_li, "label-text-alt text-error")
  end

  # Override submit button component
  override AshAuthentication.Phoenix.Components.Submit do
    set(:button_class, "btn btn-primary w-full")
    set(:disable_with_class, "btn btn-primary w-full loading")
  end

  # Override Helpers for consistent styling
  override AshAuthentication.Phoenix.Components.Helpers do
    set(:error_ul, "text-error text-sm mt-1")
    set(:error_li, "list-disc ml-4")
  end
end
