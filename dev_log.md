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
