defmodule CdcBooks.Books.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :image, :binary
    field :image_type, :string
    field :page_number, :integer

    belongs_to :book, CdcBooks.Books.Book
    has_many :translations, CdcBooks.Books.Translation

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:image, :image_type, :page_number, :book_id])
    |> validate_required([:image, :image_type, :page_number, :book_id])
  end
end
