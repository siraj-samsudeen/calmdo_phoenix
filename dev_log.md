# Development Log

## 19 Dec 2025 Friday

### Dev Database after auth setup

Logged into the DB using DBCode extension and checked the users table.

Connection Info from dev.exs:

- Host: localhost
- Port: 5432
- Username: postgres
- Password: postgres
- Database: calmdo_phoenix_dev

### Ex Machina and Faker setup

**Repositories:**

- ExMachina: https://github.com/thoughtbot/ex_machina
- Faker: https://github.com/elixirs/faker

#### Steps taken:

1. Added dependencies to `mix.exs`:
   - `{:ex_machina, "~> 2.8", only: :test}`
   - `{:faker, "~> 0.18", only: :test}`
2. Created factory module at `test/support/factory.ex`:
   - Used `ExMachina.Ecto` with repo
3. Updated `test/test_helper.exs` to start both ExMachina and Faker:
   - Added `{:ok, _} = Application.ensure_all_started(:ex_machina)` before `ExUnit.start()`
   - Added `Faker.start()` after Ecto sandbox setup
4. Made factories available in tests:
   - Added `import CalmdoPhoenix.Factory` to `ConnCase` (for LiveView/web tests)
   - Added `import CalmdoPhoenix.Factory` to `DataCase` (for context/backend tests)

#### Questions & Answers:

**Q: Why do we need `user_factory` when `user_fixture` already exists?**

**A:** They serve different purposes:

- `user_fixture`: Goes through full auth flow (register → email → magic link → confirm). Returns fully authenticated, confirmed user. Used when you need complete authenticated user.
- `user_factory`: Creates basic user struct only. No auth flow, no confirmation. Used for simple cases like associations or basic tests.

**Options:**

1. Remove factory - keep using `user_fixture` for everything (if you always need authenticated users)
2. Keep both - use factory for simple cases, fixture for authenticated users
3. Make factory call fixture - delegate to `user_fixture` for unified interface

**Q: Why do we need to update DataCase? I understand we use ConnCase in LiveView.**

**A:**

- **DataCase**: Used for backend/context tests (testing modules directly, no HTTP). Example: `test/calmdo_phoenix/accounts_test.exs`
- **ConnCase**: Used for web tests (controllers, LiveViews). Example: `test/calmdo_phoenix_web/live/project_live_test.exs`

If you only write LiveView tests, you don't need factory in DataCase. If you write context tests (like `accounts_test.exs`), you'll want factories available there too.

**Note:** Can remove factory import from DataCase if only doing LiveView tests now, add it back later if needed for context tests.

### Project Model using phx.gen

- Used --no-scope as all projects should be visible to all users

```bash
mix phx.gen.live Projects Project projects name description:text created_by:references:users --no-scope
```

- Added routes to `lib/calmdo_phoenix_web/router.ex` under browser scope

```elixir
live "/projects", ProjectLive.Index, :index
live "/projects/new", ProjectLive.Form, :new
live "/projects/:id", ProjectLive.Show, :show
live "/projects/:id/edit", ProjectLive.Form, :edit
```

## 23 Dec 2025 Tuesday

### Fix bug - created_by in project is NULL in DB

#### RED

- Updated the create test in [project_live_test.exs](test/calmdo_phoenix_web/live/project_live_test.exs) to use PhoenixTest rather than LiveViewTest
- After the create is done through the UI, we make a direct DB call to assert that the created_by is populated correctly

```elixir
new_project = Repo.get_by(Project, name: project.name)
assert new_project.created_by == user.id
```

- To create the new project, we used ExMachina to create a project_factory in the [factory.ex](test/support/factory.ex) file

```elixir
def project_factory do
   %Project{
   name: "#{System.unique_integer([:positive])} - #{Faker.Company.name()}",
   description: sequence(:description, &"Description #{&1}")
   }
end
```

- We then used :build helper to create a new project in the test

```elixir
project = build(:project)
```

#### GREEN

- We changed the [projects.ex](lib/calmdo_phoenix/projects.ex#L52) create_project function to include the scope in the changeset
- The convention as per AGENTS.md is to pass the scope as the first argument to all the context functions
- However, the changeset function already has a standard signature of project and attrs, so we needed to add the scope as the third argument

```elixir
def create_project(scope, attrs) do
  %Project{}
  |> Project.changeset(attrs, scope)
  |> Repo.insert()
end
```

- We need to pass the scope from the view to the context function - this is needed in 3 places in [form.ex](lib/calmdo_phoenix_web/live/project_live/form.ex)
- First for the save project action

```elixir

defp save_project(socket, :new, project_params) do
   case Projects.create_project(socket.assigns.current_scope, project_params) do
   ...
end
```

- then for the empty form

```elixir
defp apply_action(socket, :new, _params) do
   project = %Project{}

   socket
   |> assign(:page_title, "New Project")
   |> assign(:project, project)
   |> assign(:form, to_form(Projects.change_project(project, %{}, socket.assigns.current_scope)))
end
```

- then for the validate event when the form is changed

```elixir
@impl true
def handle_event("validate", %{"project" => project_params}, socket) do
   changeset =
   Projects.change_project(
      socket.assigns.project,
      project_params,
      socket.assigns.current_scope
   )

   {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
end
```

- for the view to get the current scope populated in socket.assigns.current_scope, we need to put the route under live_session :require_authenticated_user in [router.ex](lib/calmdo_phoenix_web/router.ex#L53)

```elixir
live_session :require_authenticated_user,
  on_mount: [{CalmdoPhoenixWeb.UserAuth, :require_authenticated}] do
  # ... other routes ...
  live "/projects/new", ProjectLive.Form, :new
end
```

#### Side effects

- Because we changed the signature of 2 functions in the projects context, we got some compile errors to be fixed
- we updated [project_fixtures.ex](test/support/fixtures/projects_fixtures.ex) to use the new signature

```elixir
def project_fixture(attrs \\ %{}) do
  project_attrs =
    Enum.into(attrs, %{
      description: "some description",
      name: "some name"
    })
  {:ok, project} = CalmdoPhoenix.Projects.create_project(build(:scope), project_attrs)
  project
end
```

- to build a scope, we had 2 choices - to follow the convention of ConnCase to define :register_and_log_in_user helper to build a scope, or to build it from scratch
- we chose to build it from scratch in [factory.ex](test/support/factory.ex)

```elixir
# TODO: is this the right way to create a user? In ConnCase, it does it differently.
def scope_factory do
  Scope.for_user(%User{
    email: sequence(:email, &"user#{&1}@example.com"),
    password: "password"
  })
end
```

**Why `insert(:scope)` did not work as we wanted to create a DB record for the user?**

- `Scope` isn't an Ecto schema with a database table 
- it's just a struct wrapper around `User` - see [scope.ex](lib/calmdo_phoenix/accounts/scope.ex). 
- ExMachina's `insert/1` tries to persist to the database via `Repo.insert`, which fails for non-Ecto structs. `build/1` just constructs the struct in memory without any DB interaction, which is exactly what we need for Scope. 

## 24 Dec 2025 Wednesday

### Precommit hooks setup

- Noticed when doing the git diff that there were some formatting differences between the previous commit and the current working tree, and decided to install the pre-commit hooks to run the `mix precommit` alias automatically.
- installed the pre-commit hook using `brew install pre-commit`
- updated the mix.exs file to include the precommit and prepush aliases
- updated the .pre-commit-config.yaml file to include the precommit and prepush hooks
- then to set up the hooks, ran `pre-commit install` - this installs the pre-commit hooks in the .git/hooks directory
- to commit these files (as we have some compiler warnings reported as errors), we are gonna use `git commit --no-verify` to bypass the pre-commit hooks

