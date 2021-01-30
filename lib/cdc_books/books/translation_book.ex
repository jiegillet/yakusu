defmodule CdcBooks.Books.TranslationBook do
  use Ecto.Schema
  import Ecto.Changeset
  alias CdcBooks.Books.{Book, Translation}
  alias CdcBooks.Languages.Language

  @required_fields ~w"title author notes translator book_id language_id"a

  schema "translation_books" do
    field :author, :string
    field :notes, :string
    field :title, :string
    field :translator, :string

    belongs_to :book, Book
    belongs_to :language, Language, type: :string
    has_many :translation, Translation

    timestamps()
  end

  @doc false
  def changeset(translation_book, attrs) do
    translation_book
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
