defmodule CdcBooks.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string
      add :author, :string
      add :language_id, references(:languages, type: :string)
      add :category_id, references(:categories, on_delete: :nothing)

      timestamps()
    end
  end
end
