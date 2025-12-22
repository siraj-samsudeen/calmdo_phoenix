defmodule CalmdoPhoenix.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :description, :text
      add :created_by, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:created_by])
  end
end
