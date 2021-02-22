defmodule Yakusu.Repo.Migrations.CreateTranslationBooks do
  use Ecto.Migration

  def change do
    create table(:translation_books) do
      add :title, :string
      add :author, :string
      add :notes, :string
      add :translator, :string
      add :language_id, references(:languages, type: :string)
      add :book_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:translation_books, [:book_id])
  end
end
