defmodule CdcBooks.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string
      add :author, :string
      add :language, :string
      add :notes, :string
      add :translator, :string
      add :translates, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:books, [:translates])
  end
end
