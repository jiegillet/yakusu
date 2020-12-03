defmodule CdcBooks.Repo.Migrations.AddBookCategory do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :category_id, references(:categories, on_delete: :nothing)
    end
  end
end
