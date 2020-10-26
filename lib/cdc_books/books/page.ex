defmodule CdcBooks.Books.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :image, :binary
    field :image_type, :string
    field :book_id, :id

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:image, :image_type])
    |> validate_required([:image, :image_type])
  end
end
