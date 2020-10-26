defmodule CdcBooks.Books.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :translation, :string
    field :page_id, :id

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:translation])
    |> validate_required([:translation])
  end
end
