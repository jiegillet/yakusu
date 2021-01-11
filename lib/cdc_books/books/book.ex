defmodule CdcBooks.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset
  alias CdcBooks.Books.{Book, Page, Category}
  alias CdcBooks.Languages.Language

  schema "books" do
    field :author, :string
    field :title, :string
    field :translator, :string
    field :notes, :string

    belongs_to :original, Book
    belongs_to :category, Category
    belongs_to :language, Language, type: :string
    has_many :pages, Page

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [
      :title,
      :author,
      :language_id,
      :notes,
      :translator,
      :original_id,
      :category_id
    ])
    |> validate_required([:title, :author, :language_id])
  end
end
