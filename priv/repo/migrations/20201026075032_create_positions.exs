defmodule CdcBooks.Repo.Migrations.CreatePositions do
  use Ecto.Migration

  def change do
    create table(:positions) do
      add :x, :integer
      add :y, :integer
      add :translation_id, references(:translations, on_delete: :nothing)

      timestamps()
    end

    create index(:positions, [:translation_id])
  end
end
