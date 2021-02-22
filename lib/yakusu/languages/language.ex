defmodule Yakusu.Languages.Language do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}

  schema "languages" do
    field :language, :string

    timestamps()
  end

  @doc false
  def changeset(language, attrs) do
    language
    |> cast(attrs, [:id, :language])
    |> validate_required([:id, :language])
  end
end
