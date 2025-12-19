# How to Test - Calmdo Testing Philosophy

## Core Philosophy

We follow a **pragmatic, user-centric testing approach** inspired by Kent Beck and DHH:

> "If a test says a project is created, it should verify the project is actually created - not just that the UI shows success."

### Guiding Principles

1. **UI tests verify the full stack** - including database persistence
2. **Avoid testing implementation details** - routes, flash messages, heading text
3. **Focus on happy paths** - edge cases go in backend tests if needed
4. **No double-loop TDD pedantry** - one UI test should give complete confidence
5. **Direct assertions over helper wrappers** - unless complexity demands it
6. **Test bugs you've encountered** - don't test hypothetical problems

---

## What to Test (and What Not to Test)

### ✅ DO Test

| What | Example | Why |
|------|---------|-----|
| **User actions work** | Click "New Project" → form appears | Core user flow |
| **Data persists to DB** | `assert Tasks.get_project_by_name("My Project")` | Real proof of creation |
| **Data displays to user** | `assert_text("My Project")` | User sees their data |
| **Critical user journeys** | Signup → Create Project → Invite User | End-to-end confidence |
| **Bugs you've had** | Delete correct project when multiple exist | Prevent regression |

### ❌ DON'T Test

| What | Example | Why |
|------|---------|-----|
| **Routes/URLs** | `assert_path(~p"/projects/new")` | Implementation detail - can change |
| **Heading text** | `assert_text("New Project")` | UI copy - not user behavior |
| **Flash messages** | `assert_text("Project created successfully")` | Implementation detail |
| **Validation in UI tests** | `fill_in("Name", with: "") \|> assert_text("can't be blank")` | Backend concern |
| **Framework behavior** | Does Phoenix routing work? | Trust the framework |
| **Hypothetical bugs** | Edge cases you haven't seen | Don't over-test |

---

## Testing Patterns

### Basic CRUD Test Pattern

```elixir
describe "basic project CRUD" do
  test "creating a project", %{conn: conn} do
    conn
    |> visit_projects()
    |> click_link("New Project")
    |> fill_in("Name", with: "Launch Campaign")
    |> submit()
    |> assert_text("Launch Campaign")  # User sees it

    # ✅ Verify DB persistence (the real proof)
    assert Tasks.get_project_by_name("Launch Campaign")
  end

  test "editing a project", %{conn: conn} do
    project = project_fixture(name: "Old Name")

    conn
    |> visit(~p"/projects/#{project}")
    |> click_link("Edit")
    |> fill_in("Name", with: "New Name")
    |> submit()
    |> assert_text("New Name")

    # ✅ Verify DB update
    assert Tasks.get_project!(project.id).name == "New Name"
  end

  test "deleting a project", %{conn: conn} do
    project_fixture(name: "To Delete")

    conn
    |> visit_projects()
    |> click_link("Delete")
    |> refute_text("To Delete")

    # ✅ Verify DB deletion
    refute Tasks.get_project_by_name("To Delete")
  end
end
```

### Edge Case Testing - Test Once

If you've encountered a bug (e.g., wrong project deleted when multiple exist), test it ONCE:

```elixir
describe "multiple projects - regression tests" do
  test "deletes correct project when multiple exist", %{conn: conn} do
    p1 = project_fixture(name: "Keep This")
    p2 = project_fixture(name: "Delete This")

    conn
    |> visit_projects()
    |> click_link("#project-#{p2.id} a", "Delete")  # Specific selector
    |> assert_text("Keep This")
    |> refute_text("Delete This")

    # Verify both UI and DB state
    assert Tasks.get_project_by_name("Keep This")
    refute Tasks.get_project_by_name("Delete This")
  end
end
```

**Why test once?**
- You've encountered this bug (DHH: "Test bugs you've had")
- One test prevents regression
- Don't duplicate across every resource (trust framework)

---

## Helpers: When to Use Them

### ✅ Use Helpers For: Navigation & Setup

**Simple, transparent, reusable**

```elixir
defp visit_projects(conn) do
  PhoenixTest.visit(conn, ~p"/projects")
  # OR if navigation changes:
  # conn |> visit(~p"/") |> click_link("Projects")
end
```

**Benefits:**
- Abstracts "how to get there" from "what to test"
- Change navigation once, all tests adapt
- Clear intent: "visit_projects" is self-documenting

### ❌ DON'T Use Helpers For: Assertions

**Direct code is clearer**

```elixir
# ❌ Over-abstraction - adds indirection:
assert_project_exists("My Project")
refute_project_exists("Deleted")

# ✅ Direct - obvious what's happening:
assert Tasks.get_project_by_name("My Project")
refute Tasks.get_project_by_name("Deleted")
```

**Exception:** Complex assertions repeated everywhere:

```elixir
# If you're constantly writing:
assert Tasks.get_project_by_name("My Project",
  scope: current_user,
  preload: [:tasks, :members],
  filter: :active
)

# Then a helper makes sense:
assert_user_has_active_project(current_user, "My Project")
```

**Litmus test:**
> "Does this helper make the test easier to read or harder to read?"

---

## Database Verification

### Prefer Context Functions, BUT Direct Repo is OK for Simple Verification

**The Pragmatic Rule (DHH-style):**
> "Use Context functions when they exist. Use Repo directly for simple test verification when production doesn't need the function yet."

### When to Use Direct Repo Access (✅ OK)

```elixir
# ✅ Simple verification - production doesn't need this query:
test "creating a project" do
  conn |> ... |> submit()

  # Direct Repo for test verification
  assert Repo.get_by(Project, name: "Launch Campaign")
end

# ✅ Deletion verification:
refute Repo.get_by(Project, name: "Deleted Project")
```

**When this is acceptable:**
- Just for assertion/verification (not test logic)
- No authorization/scoping logic involved
- Production code doesn't need this query
- Don't want to add Context function just for tests (YAGNI)

### When to Use Context Functions (✅ Prefer)

```elixir
# ✅ Context function exists:
assert Tasks.get_project!(scope, project.id)

# ✅ Authorization/scoping matters:
assert Tasks.list_projects(scope) |> length() == 2
```

**When this is required:**
- Context function already exists
- Authorization/scoping logic applies
- Natural domain operation production will need
- In Ash: ALWAYS (bypassing Resource actions breaks policies)

### When to Add Context Function

**Add the function if:**
- Production code needs it (or will soon)
- It's a natural domain operation
- Authorization/scoping matters

**Don't add if:**
- Only tests need it
- It's just for verification convenience
- Production queries by ID, not by name

### The Ash Perspective (Future)

**In Ash, you MUST use Resource actions:**

```elixir
# ❌ BREAKS - bypasses policies:
Repo.get_by(Project, name: "Secret")  # Ignores authorization!

# ✅ REQUIRED - respects policies:
Project.by_name!("Secret", actor: current_user)  # Checks authorization
```

When moving to Ash, add Resource queries for test verification.

---

## Validation Testing

### Happy Paths Only in UI Tests

```elixir
# ❌ Don't test validation in UI:
test "shows error for blank name" do
  conn
  |> visit_projects()
  |> click_link("New Project")
  |> fill_in("Name", with: "")
  |> submit()
  |> assert_text("can't be blank")  # Testing validation UX
end
```

### Test Complex Validation at Backend

```elixir
# ✅ Backend test for complex validation:
test "prevents duplicate project names" do
  user = user_fixture()
  project_fixture(name: "Duplicate", user: user)

  assert {:error, changeset} =
    Tasks.create_project(%{name: "Duplicate", user_id: user.id})
  assert "already exists" in errors_on(changeset).name
end
```

**When to test validation:**
1. **Simple validations** (presence, length) → Trust the framework, no tests
2. **Complex business logic** → Backend test
3. **Critical UX** (rare) → UI test only if error message is critical

---

## Test Data Attributes

### Our Decision: Don't Use Them

**Cost:**
```html
<!-- Clutters templates -->
<button data-test="delete-project" data-project-id={@project.id}>
  Delete
</button>
```

**Benefit:**
- Slightly more stable selectors (debatable)

**Verdict:** Not worth it for our team size and tech stack.

**Use instead:**
```elixir
# ✅ Semantic selectors:
click_link("#project-#{project.id} a", "Delete")

# ✅ Simple text matching:
click_link("Delete")
```

**When data-test attributes ARE worth it:**
- Large organization with dedicated QA team
- Complex SPA with heavy JavaScript
- Third-party E2E tools requiring stable selectors

---

## What the Experts Say

### DHH (Rails, Ruby)
> "Write the test that would have caught the bug you actually had. Otherwise, test the happy path and move on."

**Philosophy:**
- System tests verify the whole stack
- Don't test framework behavior
- Test bugs you've encountered, not hypothetical ones

### Kent Beck (TDD)
> "Test until fear turns to boredom. Test what could break, not what can't."

**Philosophy:**
- Write tests to reduce fear/uncertainty
- Once you're confident, stop testing
- Don't test the same thing twice

**His rule:** "Don't test to prove you're thorough. Test to gain confidence."

### Kent C. Dodds (Testing Library)
> "The more your tests resemble the way your software is used, the more confidence they give you."

**On test attributes:**
- Avoid data-testid - couples tests to implementation
- Use accessible queries (roles, labels, text)
- If you can't test semantically, fix the HTML accessibility

---

## Phoenix vs Ash Testing

### Phoenix Convention (What We Started With)

```elixir
# Separate UI and Context tests
test "creates project via UI" do
  conn |> visit(...) |> submit()
  assert html =~ "Project created"
end

test "Context.create_project/1" do
  assert {:ok, project} = Tasks.create_project(attrs)
end
```

**Result:** Testing the same behavior twice (duplication)

### Our Approach (Pragmatic)

```elixir
# One UI test verifies full stack
test "user can create a project" do
  conn |> visit(...) |> submit()
  assert_text("My Project")
  assert Tasks.get_project_by_name("My Project")  # Verify DB
end

# Context tests only for complex logic
test "validates duplicate project names" do
  # Complex validation logic
end
```

### Ash Framework Approach (Future)

In Ash, Resources ARE your application:

```elixir
# Test Resources exhaustively
test "Project.create validates name" do
  assert {:error, _} = Project.create(%{name: nil})
end

# UI tests minimal - just wiring
test "new project form renders" do
  conn |> visit(~p"/projects/new") |> assert_has("form")
end
```

**Ash philosophy:** "Test your domain (Resources), not your plumbing (UI)."

---

## Decision Summary

| Question | Decision | Rationale |
|----------|----------|-----------|
| **DB verification in UI tests?** | ✅ Yes | Full stack confidence |
| **Test routes/flash messages?** | ❌ No | Implementation details |
| **Assertion helper wrappers?** | ❌ No (usually) | Direct code is clearer |
| **Navigation helpers?** | ✅ Yes | Transparent, reusable |
| **Test validation in UI?** | ❌ No | Backend concern |
| **Test multi-item edge cases?** | ✅ Once if you've seen the bug | Prevent regression |
| **Use data-test attributes?** | ❌ No | Cost > benefit for our team |
| **Use Context functions?** | ✅ Yes | Respect domain boundaries |

---

## Examples

### Good Test (Follows Our Philosophy)

```elixir
test "user can create and delete a project", %{conn: conn} do
  # Create
  conn
  |> visit_projects()
  |> click_link("New Project")
  |> fill_in("Name", with: "Launch Campaign")
  |> submit()
  |> assert_text("Launch Campaign")

  project = Tasks.get_project_by_name("Launch Campaign")
  assert project.name == "Launch Campaign"

  # Delete
  conn
  |> visit_projects()
  |> click_link("Delete")
  |> refute_text("Launch Campaign")

  refute Tasks.get_project_by_name("Launch Campaign")
end
```

**Why it's good:**
- ✅ Tests user behavior
- ✅ Verifies DB state
- ✅ No implementation details
- ✅ Direct assertions
- ✅ Happy path

### Bad Test (Violates Our Philosophy)

```elixir
test "creates project with validation", %{conn: conn} do
  conn
  |> visit(~p"/projects")
  |> click_link("New Project")
  |> assert_path(~p"/projects/new")  # ❌ Implementation detail
  |> assert_text("New Project")  # ❌ Heading text
  |> fill_in("Name", with: "")
  |> submit()
  |> assert_text("can't be blank")  # ❌ Validation in UI test
  |> fill_in("Name", with: "My Project")
  |> submit()
  |> assert_path(~p"/projects")  # ❌ Implementation detail
  |> assert_text("Project created successfully")  # ❌ Flash message
  # ❌ Missing: DB verification!
end
```

**Why it's bad:**
- ❌ Tests routes (implementation detail)
- ❌ Tests UI copy (brittle)
- ❌ Tests validation (wrong layer)
- ❌ Doesn't verify DB persistence

---

## Quick Reference

### Test Checklist

Before writing a test, ask:

1. **What user behavior am I testing?** (not "what code am I testing?")
2. **Does this test verify actual state change?** (DB, not just UI)
3. **Am I testing implementation details?** (routes, text, selectors)
4. **Would this test break if I refactor?** (bad if yes)
5. **Have I encountered this bug?** (if no, maybe skip)
6. **Does this helper add clarity?** (if no, don't create it)

### Anti-Patterns to Avoid

```elixir
# ❌ assert_path(~p"/projects/new")
# ❌ assert_text("New Project")  # heading
# ❌ assert_text("Project created successfully")  # flash
# ❌ fill_in("Name", with: "") |> assert_text("can't be blank")
# ❌ assert_project_exists("My Project")  # needless helper
# ❌ Repo.get_by(Project, name: "...")  # bypass Context
```

### Patterns to Follow

```elixir
# ✅ click_link("New Project")  # user action
# ✅ assert_text("My Project")  # user data
# ✅ assert Tasks.get_project_by_name("My Project")  # DB via Context
# ✅ refute Tasks.get_project_by_name("Deleted")
# ✅ visit_projects()  # simple helper
# ✅ Test edge cases once if you've seen the bug
```

---

## Appendix: Testing Philosophy Evolution

### Before This Discussion
- Followed Phoenix convention blindly
- Tested UI and Context separately (duplication)
- Used assertion wrappers everywhere
- Tested implementation details (routes, flash messages)
- No DB verification in UI tests

### After This Discussion
- Pragmatic, user-centric approach
- UI tests verify full stack (including DB)
- Direct assertions (minimal helpers)
- Avoid implementation details
- Test bugs we've encountered
- Happy paths in UI, edge cases in backend

### Future (Moving to Ash)
- Test Resources exhaustively
- Minimal UI tests (just wiring)
- Trust the framework more
- Domain-driven testing
