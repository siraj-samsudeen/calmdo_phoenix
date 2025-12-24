defmodule CalmdoPhoenix.Repo.Migrations.AddNotNullForCreatedByInProject do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      modify :created_by, :integer, null: false
    end
  end
end
