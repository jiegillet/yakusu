defmodule CdcBooks.Books.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :text, :string

    belongs_to :page, CdcBooks.Books.Translation
    belongs_to :book, CdcBooks.Books.Book
    has_many :positions, CdcBooks.Books.Position

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:text, :page_id, :book_id])
    |> validate_required([:text, :page_id, :book_id])
  end
end
