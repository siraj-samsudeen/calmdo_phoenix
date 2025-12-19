# Phoenix Testing Guidelines

This document contains guidelines for writing tests in this Phoenix application using PhoenixTest.

## Test Philosophy

See `docs/how-to-test.md` for the full testing philosophy. Key principles:

- UI tests verify the full stack (including DB persistence)
- Avoid testing implementation details (routes, flash messages, heading text)
- Test bugs you've encountered, not hypothetical problems
- Happy paths in UI tests, edge cases in backend tests


## PhoenixTest Library

We use [PhoenixTest](https://hexdocs.pm/phoenix_test/PhoenixTest.html) for e2e/integration tests. It provides a unified API that works seamlessly with both LiveView and static pages.

### Core Pattern

```elixir
conn
|> visit(~p"/projects")
|> click_link("New Project")
|> fill_in("Name", with: "My Project")
|> submit()
|> assert_text("My Project")
```

### Key Functions

| Function                | Purpose                             |
| ----------------------- | ----------------------------------- |
| `visit/2`               | Entry point - navigates to a URL    |
| `click_link/2`          | Click a link by text                |
| `click_button/2`        | Click a button by text              |
| `fill_in/3`             | Fill input by label text            |
| `select/3`              | Choose dropdown option              |
| `choose/3`              | Select radio button                 |
| `check/3` / `uncheck/3` | Toggle checkboxes                   |
| `submit/1`              | Submit form (triggers phx-submit)   |
| `assert_text/2`         | Assert text is visible              |
| `refute_text/2`         | Assert text is NOT visible          |
| `assert_has/2, /3`      | Assert element exists (by selector) |
| `refute_has/2, /3`      | Assert element does NOT exist       |

### What NOT to Use

- `assert_path/2` - Implementation detail, routes can change
- Testing flash messages - Implementation detail
- Testing heading text - UI copy, not user behavior

## Project E2E Test Pattern

Reference implementation: `test/calmdo_web/projects_e2e_test.exs`

```elixir
defmodule CalmdoWeb.ProjectsE2eTest do
  use CalmdoWeb.ConnCase
  import Calmdo.ProjectsFixtures

  setup :register_and_log_in_user

  describe "project e2e" do
    test "project CRUD", %{conn: conn} do
      conn
      |> visit(~p"/projects")
      |> click_link("New Project")
      |> fill_in("Name", with: "Test Project 1")
      |> submit()
      |> assert_text("Test Project 1")

      # visit the show page
      |> click_link("Show")
      |> assert_text("Test Project 1")
      # back to project lists page
      |> click_link("Back")

      # edit the project, assuming a single project
      |> click_link("Edit")
      |> fill_in("Name", with: "Test Project 1 updated")
      |> submit()
      |> assert_text("Test Project 1 updated")

      # delete the project, assuming a single project
      |> click_link("Delete")
      |> refute_text("Test Project 1 updated")
    end

    # separate test to check more complex features not covered in CRUD
    test "show project", %{conn: conn, scope: scope} do
      project = project_fixture(scope, name: "Product Launch")

      conn
      |> visit(~p"/projects/#{project}")
      |> assert_text("Product Launch")
    end
  end
end
```

### Key Patterns From This Example

1. **Use `CalmdoWeb.ConnCase`** - imports PhoenixTest and test helpers
2. **Use `setup :register_and_log_in_user`** - provides `conn`, `user`, and `scope` in test context
3. **Use fixtures for test data** - `project_fixture(scope, name: "...")` from `Calmdo.ProjectsFixtures`
4. **Chain operations with pipe** - natural flow from action to assertion
5. **Test full CRUD in one test** - when testing basic happy paths
6. **Separate tests for complex features** - when fixture data is needed

## Test File Structure

```
test/
├── calmdo/                      # Context/backend tests
│   └── projects_test.exs        # Complex business logic tests
├── calmdo_web/                  # E2E/integration tests
│   └── projects_e2e_test.exs    # User flow tests with PhoenixTest
└── support/
    ├── conn_case.ex             # Test case for web tests
    ├── data_case.ex             # Test case for data tests
    ├── test_helpers.ex          # Shared test helpers
    └── fixtures/
        └── projects_fixtures.ex # Factory for creating test data
```

## Test Setup

### ConnCase Provides

- `@endpoint CalmdoWeb.Endpoint` - for routing
- `~p` sigil for verified routes
- `Plug.Conn` and `Phoenix.ConnTest` imports
- `PhoenixTest` import
- `Calmdo.TestHelpers` import

### Authentication Setup

```elixir
# In your test module:
setup :register_and_log_in_user

# This provides in test context:
# - conn: logged-in connection
# - user: the created user
# - scope: Calmdo.Accounts.Scope.for_user(user)
```

## Writing E2E Tests

### ✅ DO

```elixir
test "user can create a project", %{conn: conn} do
  conn
  |> visit(~p"/projects")
  |> click_link("New Project")
  |> fill_in("Name", with: "Launch Campaign")
  |> submit()
  |> assert_text("Launch Campaign")

  # Verify DB persistence via Context
  assert Projects.get_project_by_name("Launch Campaign")
end
```

### ❌ DON'T

```elixir
test "creates project", %{conn: conn} do
  conn
  |> visit(~p"/projects")
  |> assert_path(~p"/projects")           # ❌ Implementation detail
  |> click_link("New Project")
  |> assert_text("New Project")           # ❌ Testing heading text
  |> fill_in("Name", with: "")
  |> submit()
  |> assert_text("can't be blank")        # ❌ Validation in UI test
  |> fill_in("Name", with: "My Project")
  |> submit()
  |> assert_text("Project created")       # ❌ Flash message
  # ❌ Missing DB verification!
end
```

## Form Handling

### Basic Form Submission

```elixir
conn
|> visit(~p"/projects/new")
|> fill_in("Name", with: "My Project")
|> fill_in("Description", with: "A description")
|> submit()
```

### Forms With Multiple Similar Labels

Use `within/3` to scope:

```elixir
conn
|> visit(~p"/settings")
|> within("#profile-form", fn session ->
  session
  |> fill_in("Name", with: "New Name")
  |> submit()
end)
```

### Select, Radio, Checkbox

```elixir
conn
|> select("Status", option: "Active")
|> choose("Priority", option: "High")
|> check("Send notifications")
|> uncheck("Archive old items")
```

## Assertions

### Text Assertions

```elixir
|> assert_text("My Project")        # Text is visible
|> refute_text("Deleted Project")   # Text is NOT visible
```

### Element Assertions

```elixir
|> assert_has("#project-form")                    # Element exists
|> assert_has(".project-card", text: "My Project") # Element with text
|> assert_has(".project-card", count: 3)          # Specific count
|> refute_has(".error-message")                   # Element doesn't exist
```

## Fixtures

### Using Fixtures

```elixir
import Calmdo.ProjectsFixtures

test "shows project", %{conn: conn, scope: scope} do
  project = project_fixture(scope, name: "Test Project")

  conn
  |> visit(~p"/projects/#{project}")
  |> assert_text("Test Project")
end
```

### Creating Fixtures

Fixtures live in `test/support/fixtures/`. Pattern:

```elixir
defmodule Calmdo.ProjectsFixtures do
  def project_fixture(scope, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{name: "some name"})
    {:ok, project} = Calmdo.Projects.create_project(scope, attrs)
    project
  end
end
```

## DB Verification

### Prefer Context Functions

```elixir
# ✅ Good - uses Context
assert Projects.get_project_by_name("My Project")
refute Projects.get_project_by_name("Deleted")

# ✅ Good - Context function exists
assert Projects.get_project!(scope, project.id)
```

### Direct Repo OK for Simple Verification

```elixir
# ✅ OK - simple verification, no auth needed
assert Repo.get_by(Project, name: "My Project")
refute Repo.get_by(Project, name: "Deleted")
```

Use Repo directly only when:
- Just for assertion/verification
- No authorization/scoping involved
- Don't want to add Context function just for tests (YAGNI)

## Debugging Tests

### Print Current HTML

```elixir
conn
|> visit(~p"/projects")
|> tap(fn session ->
  IO.puts(PhoenixTest.Driver.render_page_title(session))
end)
```

### Open Browser

```elixir
# Development only - remove before commit
conn
|> visit(~p"/projects")
|> open_browser()
```

### Using LazyHTML for Debugging

```elixir
html = render(view)
document = LazyHTML.from_fragment(html)
matches = LazyHTML.filter(document, "#my-selector")
IO.inspect(matches, label: "Matches")
```

## Test Commands

```bash
# Run all tests
mix test

# Run specific test file
mix test test/calmdo_web/projects_e2e_test.exs

# Run specific test (by line number)
mix test test/calmdo_web/projects_e2e_test.exs:8

# Run previously failed tests
mix test --failed

# Run with verbose output
mix test --trace
```

## Common Issues

### Element Not Found

1. Check the selector - print HTML to see actual structure
2. LiveView may not have updated yet - use `assert_has/3` with timeout
3. Element may be inside a form - check if you need `within/3`

### Form Not Submitting

1. Ensure form has `phx-submit` for LiveView
2. Check if using `submit()` vs `click_button("Submit")`
3. LiveView forms may need `render_submit/2` from `Phoenix.LiveViewTest`

### Authentication Issues

1. Ensure `setup :register_and_log_in_user` is in your test module
2. Check that route requires authentication in router
3. Verify `scope` is being passed correctly to fixtures

## Quick Reference

### Test Checklist

Before writing a test:

1. What user behavior am I testing? (not implementation)
2. Does this test verify actual state change? (DB, not just UI)
3. Am I avoiding implementation details? (routes, flash, headings)
4. Would this test break if I refactor? (bad if yes)
5. Have I encountered this bug? (if no, maybe skip)

### Anti-Patterns

```elixir
# ❌ assert_path(~p"/projects/new")
# ❌ assert_text("New Project")  # heading
# ❌ assert_text("Project created successfully")  # flash
# ❌ fill_in("Name", with: "") |> assert_text("can't be blank")
# ❌ Missing DB verification after mutations
```

### Patterns to Follow

```elixir
# ✅ click_link("New Project")  # user action
# ✅ assert_text("My Project")  # user data (not headings)
# ✅ assert Projects.get_project_by_name("My Project")  # DB via Context
# ✅ refute Projects.get_project_by_name("Deleted")
# ✅ Test edge cases once if you've seen the bug
```
