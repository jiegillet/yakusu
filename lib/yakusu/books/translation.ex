defmodule Yakusu.Books.Translation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Yakusu.Books.{Page, TranslationBook}

  schema "translations" do
    field :text, :string, default: ""
    field :path, :string, default: ""

    belongs_to :page, Page
    belongs_to :translation_book, TranslationBook

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:text, :path, :page_id, :translation_book_id])
    |> validate_required([:page_id, :translation_book_id])
  end
end
