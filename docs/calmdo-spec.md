# To-Do Application Specification

## Data Model

### Project

- Fields
  - id
  - name (string, required, max 100 chars)
  - description (string, optional)
  - created_by (user_id, fk, required, default to current user)
  - created_at, updated_at
- Rules
  - Deleting a project deletes its tasks and time logs.

⸻

### Task

- Fields
  - id
  - project_id (fk)
  - title (string, required, max 200 chars)
  - description (string, optional)
  - status: todo | in_progress | done (default: todo)
  - position (integer, default 0)
  - assigned_to (user_id, fk)
  - created_by, updated_by (user_id, fk, required, default to current user)
  - created_at, updated_at
- Rules
  - Tasks can be moved up and down the list.
  - Completed tasks can be reopened.

⸻

### TimeLog

- Fields
  - id
  - task_id (fk)
  - minutes (integer > 0, required)
  - note (string, optional)
  - date (date, default today)
  - created_by, updated_by (user_id, fk, required, default to current user)
  - created_at, updated_at

⸻

## Core User Journeys

### Happy Path 1

- Create a project.
- Create tasks inside a project.
- Start a task as in_progress and later mark it as done.
- Log time against a task.
- Task should display the total time logged for the task.
- Project should display the number of tasks and total time logged for the project .

## UI Defaults

- Sidebar list of projects.
- Main pane displays tasks for selected project.
- Users should see the tasks that are assigned to them by default with options to view all tasks or tasks created by them.

## Validations

- Only logged in user can create a project and tasks.

## Permissions

- Users can view all projects and tasks by default.
- All users can edit any project, task and time log.
- Users can only delete projects and tasks they have created.

## Reporting

- List of projects with number of tasks and total time logged across all tasks.
- Total time logged grouped by day or week.
