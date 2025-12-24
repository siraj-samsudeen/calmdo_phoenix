defmodule CalmdoPhoenix.ProjectsTest do
  use CalmdoPhoenix.DataCase

  alias CalmdoPhoenix.Projects
  import CalmdoPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]

  describe "projects" do
    alias CalmdoPhoenix.Projects.Project

    import CalmdoPhoenix.ProjectsFixtures

    @invalid_attrs %{"name" => nil, "description" => nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{"name" => "some name", "description" => "some description"}

      assert {:ok, %Project{} = project} =
               Projects.create_project(user_scope_fixture(), valid_attrs)

      assert project.name == "some name"
      assert project.description == "some description"
    end

    @tag :focus
    test "create project without created_by should be rejected" do
      # Test changeset validation
      changeset = Project.changeset(%Project{}, params_for(:project))
      assert "can't be blank" in errors_on(changeset).created_by

      # Test DB constraint separately
      assert_raise Postgrex.Error, ~r/not_null_violation/, fn ->
        Repo.insert!(build(:project))
      end
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Projects.create_project(user_scope_fixture(), @invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.description == "some updated description"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end
end
