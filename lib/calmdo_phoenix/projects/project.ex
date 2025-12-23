defmodule CalmdoPhoenix.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string
    field :created_by, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs, scope) do
    project
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> put_change(:created_by, scope.user.id)
  end
end
