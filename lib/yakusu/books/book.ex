defmodule Yakusu.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset
  alias Yakusu.Books.{Page, Category, TranslationBook}
  alias Yakusu.Languages.Language

  @required_fields ~w"title author language_id category_id"a

  schema "books" do
    field :author, :string
    field :title, :string

    belongs_to :category, Category
    belongs_to :language, Language, type: :string
    has_many :pages, Page
    has_many :translation_books, TranslationBook

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
