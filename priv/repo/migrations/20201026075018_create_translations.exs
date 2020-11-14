defmodule CdcBooks.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :text, :string
      add :page_id, references(:pages, on_delete: :nothing)
      add :book_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:translations, [:page_id, :book_id])
  end
end
