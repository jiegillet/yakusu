defmodule CdcBooks.Repo.Migrations.AlterBookLanguageRef do
  use Ecto.Migration

  def change do
    alter table(:books) do
      add :language_id, references(:languages, type: :string)
    end
  end
end
