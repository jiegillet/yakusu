defmodule Yakusu.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :image, :binary
      add :image_type, :string
      add :height, :integer
      add :width, :integer
      add :page_number, :integer
      add :book_id, references(:books, on_delete: :nothing)

      timestamps()
    end

    create index(:pages, [:book_id])
  end
end
