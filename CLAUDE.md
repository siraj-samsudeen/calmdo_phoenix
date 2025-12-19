# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

```bash
# Development
mix setup              # Install deps, create DB, run migrations, build assets
mix phx.server         # Start Phoenix server (localhost:4000)
iex -S mix phx.server  # Start with interactive shell

# Testing
mix test               # Run all tests
mix test path/to/test.exs           # Run specific test file
mix test path/to/test.exs:42        # Run test at specific line
mix test --failed                   # Re-run failed tests

# Database
mix ecto.create        # Create database
mix ecto.migrate       # Run migrations
mix ecto.reset         # Drop, create, migrate, seed

# Code Quality
mix precommit          # Run before committing (compile warnings, format, test)
mix format             # Format code
mix compile --warning-as-errors     # Compile with strict warnings
```

## Project Overview

Phoenix 1.8 application using:

- **Elixir 1.15+** with Phoenix 1.8.1
- **PostgreSQL** via Ecto 3.13
- **LiveView 1.1** for real-time UI
- **Tailwind CSS v4** (no tailwind.config.js needed)
- **esbuild** for JS bundling
- **Bandit** web server
- **Swoosh** for emails (dev mailbox at `/dev/mailbox`)

## Architecture

```
lib/
├── calmdo_phoenix/           # Business logic (contexts)
│   ├── repo.ex               # Ecto repository
│   ├── mailer.ex             # Email delivery
│   └── application.ex        # OTP supervision tree
└── calmdo_phoenix_web/       # Web layer
    ├── router.ex             # Route definitions
    ├── endpoint.ex           # HTTP endpoint config
    ├── components/
    │   ├── core_components.ex  # Reusable UI components (<.button>, <.input>, etc.)
    │   └── layouts.ex        # App layouts (root, app)
    └── controllers/          # Controllers and templates

test/
├── support/
│   ├── conn_case.ex          # Use for controller/LiveView tests
│   └── data_case.ex          # Use for context/schema tests
```

## Key Conventions

### Module Naming

- **Contexts**: `CalmdoPhoenix.ContextName` (e.g., `CalmdoPhoenix.Accounts`)
- **Schemas**: `CalmdoPhoenix.ContextName.SchemaName` (e.g., `CalmdoPhoenix.Accounts.User`)
- **LiveViews**: `CalmdoPhoenixWeb.FeatureLive` (always `Live` suffix)
- **Controllers**: `CalmdoPhoenixWeb.FeatureController`

### Router Scopes

The default browser scope is aliased to `CalmdoPhoenixWeb`, so routes use short module names:

```elixir
scope "/", CalmdoPhoenixWeb do
  pipe_through :browser
  live "/dashboard", DashboardLive   # Points to CalmdoPhoenixWeb.DashboardLive
end
```

### Test Helpers

- `CalmdoPhoenixWeb.ConnCase` - for controller/LiveView tests (provides `conn`)
- `CalmdoPhoenix.DataCase` - for context/schema tests (provides `errors_on/1`)
- `LazyHTML` - for HTML assertions in tests

## Critical Rules

**Read AGENTS.md before writing any code.** It contains mandatory Phoenix 1.8 patterns including:

- LiveView template structure (always wrap with `<Layouts.app>`)
- Form handling (`to_form/2`, never use changesets directly in templates)
- LiveView streams (always use for collections, never `phx-update="append"`)
- HEEx syntax rules (interpolation, conditionals, class lists)
- Component usage (`<.icon>`, `<.input>`, `<.form>`)

### HTTP Client

Use `Req` for HTTP requests (already included). Never use HTTPoison, Tesla, or :httpc.

### Assets

- Tailwind v4 uses `@import "tailwindcss"` syntax in `app.css`
- Never use `@apply` in CSS
- No external script/link tags - import everything through `app.js`/`app.css`

## User Preferences

- Use PhoenixTest for testing both LiveView and Controller tests and do NOT use the default LiveViewTest module
