defmodule CalmdoPhoenix.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CalmdoPhoenix.Projects` context.
  """

  @doc """
  Generate a project.
  """
  import CalmdoPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]

  def project_fixture(attrs \\ %{}) do
    project_attrs =
      Enum.into(attrs, %{
        "description" => "some description",
        "name" => "some name"
      })

    {:ok, project} = CalmdoPhoenix.Projects.create_project(user_scope_fixture(), project_attrs)

    project
  end
end
