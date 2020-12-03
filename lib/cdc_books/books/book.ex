defmodule CdcBooks.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset
  alias CdcBooks.Books
  alias CdcBooks.Books.{Book, Page, Category}

  schema "books" do
    field :author, :string
    field :language, :string
    field :title, :string
    field :translator, :string
    field :notes, :string

    belongs_to :original, Book
    has_many :pages, Page
    belongs_to :category, Category

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :language, :notes, :translator, :original_id, :category_id])
    |> validate_required([:title, :author, :language])
  end
end
