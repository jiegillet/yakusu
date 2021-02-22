defmodule Yakusu.Repo.Migrations.CreateLanguages do
  use Ecto.Migration

  def change do
    create table(:languages, primary_key: false) do
      add :id, :string, primary_key: true
      add :language, :string

      timestamps()
    end

  end
end
