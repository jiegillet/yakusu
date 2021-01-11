defmodule CdcBooks.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string
      add :author, :string
      add :notes, :string
      add :translator, :string
      add :original_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:books, [:original_id])
  end
end
