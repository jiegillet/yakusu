defmodule CdcBooks.Books.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :text, :string
    field :path, :string

    belongs_to :page, CdcBooks.Books.Translation
    belongs_to :book, CdcBooks.Books.Book

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:text, :path, :page_id, :book_id])
    |> validate_required([:text, :path, :page_id, :book_id])
  end
end
