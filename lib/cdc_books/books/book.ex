defmodule CdcBooks.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :author, :string
    field :language, :string
    field :notes, :string
    field :title, :string
    field :translator, :string
    field :translates, :id

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :language, :notes, :translator])
    |> validate_required([:title, :author, :language, :notes, :translator])
  end
end
