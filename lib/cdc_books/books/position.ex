defmodule CdcBooks.Books.Position do
  use Ecto.Schema
  import Ecto.Changeset

  schema "positions" do
    field :x, :integer
    field :y, :integer
    field :group, :integer
    field :translation_id, :id

    #    belongs_to :translations, CdcBooks.Books.Translation

    timestamps()
  end

  @doc false
  def changeset(position, attrs) do
    position
    |> cast(attrs, [:x, :y])
    |> validate_required([:x, :y])
  end
end
