defmodule Yakusu.Repo.Migrations.CreateTranslations do
  use Ecto.Migration

  def change do
    create table(:translations) do
      add :text, :text
      add :path, :text
      add :page_id, references(:pages, on_delete: :nothing)
      add :translation_book_id, references(:translation_books, on_delete: :nothing)

      timestamps()
    end

    create index(:translations, [:page_id, :translation_book_id])
  end
end
