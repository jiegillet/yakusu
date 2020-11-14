defmodule CdcBooks.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset

  schema "books" do
    field :author, :string
    field :language, :string
    field :title, :string
    field :translator, :string
    field :notes, :string

    belongs_to :original, CdcBooks.Books.Book 
    has_many :pages, CdcBooks.Books.Page

    timestamps()
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:title, :author, :language, :notes, :translator, :original_id])
    |> validate_required([:title, :author, :language])
  end
end
