defmodule CdcBooks.Books.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @required_attrs ~w"image image_type width height page_number book_id"a

  schema "pages" do
    field :image, :binary
    field :image_type, :string
    field :width, :integer
    field :height, :integer
    field :page_number, :integer

    belongs_to :book, CdcBooks.Books.Book
    has_many :translations, CdcBooks.Books.Translation

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
  end
end
