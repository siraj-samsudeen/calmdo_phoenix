defmodule CalmdoPhoenix.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CalmdoPhoenix.Projects` context.
  """

  @doc """
  Generate a project.
  """
  import CalmdoPhoenix.Factory

  def project_fixture(attrs \\ %{}) do
    project_attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, project} = CalmdoPhoenix.Projects.create_project(build(:scope), project_attrs)

    project
  end
end
