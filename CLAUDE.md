# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RubberduckWeb is a Phoenix 1.8 web application using the Ash framework for domain modeling and authentication. The project requires Elixir ~> 1.15 and Phoenix ~> 1.8.0.

## Essential Commands

### Development
- `mix setup` - Install and setup dependencies (run this first)
- `mix phx.server` - Start Phoenix server on port 4000
- `iex -S mix phx.server` - Start server with interactive shell

### Testing & Quality
- `mix test` - Run all tests
- `mix test path/to/test.exs` - Run specific test file
- `mix test --failed` - Re-run only failed tests
- `mix precommit` - Run compilation (with warnings as errors), formatting, tests, and clean unused deps

### Asset Management
- `mix assets.setup` - Install Node dependencies for Tailwind and esbuild
- `mix assets.build` - Build assets for development
- `mix assets.deploy` - Build and minify assets for production

## Architecture & Key Patterns

### Domain Layer (Ash Framework)
The application uses Ash for domain modeling. Resources are located in `/lib/rubberduck_web/`:
- **Accounts Domain**: User management with authentication
  - `User` resource with email confirmation and password reset
  - `Token` resource for authentication tokens
  - `ApiKey` resource for programmatic access

When working with Ash resources:
- Actions define business logic operations
- Policies control authorization
- Attributes and relationships define data structure
- Use `Ash.Query` for querying and `Ash.Changeset` for mutations

### Web Layer
Located in `/lib/rubberduck_web_web/`:
- Controllers follow standard Phoenix REST patterns
- LiveViews for interactive UI components
- Components in `/components/` using function components
- Templates use HEEx syntax (`.html.heex` files)

### Authentication
Uses AshAuthentication and AshAuthenticationPhoenix:
- Email/password authentication with confirmation
- Password reset functionality
- API key authentication for programmatic access
- Auth forms and components in `lib/rubberduck_web_web/controllers/auth/`

### Testing Approach
- Use `ConnCase` for controller tests
- LiveView tests use `Phoenix.LiveViewTest`
- LazyHTML for HTML assertions
- Test files mirror the lib structure under `/test/`

## Important Development Notes

### When Creating New Features
1. Define Ash resources in `/lib/rubberduck_web/` with appropriate actions and policies
2. Create corresponding web layer components in `/lib/rubberduck_web_web/`
3. Follow Phoenix conventions for naming and file structure
4. Write tests for both domain logic and web layer

### Form Handling
- Use Phoenix.HTML.Form helpers with Ash changesets
- AshPhoenix provides form integration for Ash resources
- Always validate data at the resource level using Ash validations

### Asset Pipeline
- JavaScript: esbuild compiles from `/assets/js/`
- CSS: Tailwind CSS with configuration in `/assets/tailwind.config.js`
- Static assets served from `/priv/static/`

### Configuration
- Environment-specific config in `/config/{dev,test,prod}.exs`
- Runtime configuration in `/config/runtime.exs` for production secrets
- Use `Application.get_env/3` to access configuration values

### Code Quality
- Always run `mix precommit` before committing changes
- The formatter is configured with Spark and Phoenix LiveView HTML formatting
- Compilation warnings are treated as errors in precommit checks