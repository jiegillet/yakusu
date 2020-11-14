defmodule CdcBooks.Books.Position do
  use Ecto.Schema
  import Ecto.Changeset

  schema "positions" do
    field :x, :integer
    field :y, :integer
    field :group, :integer

    belongs_to :translation, CdcBooks.Books.Translation

    timestamps()
  end

  @doc false
  def changeset(position, attrs) do
    position
    |> cast(attrs, [:x, :y, :group, :translation_id])
    |> validate_required([:x, :y, :group, :translation_id])
  end
end
