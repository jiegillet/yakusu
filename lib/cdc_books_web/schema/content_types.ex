defmodule CdcBooksWeb.Schema.BooksTypes do
  use Absinthe.Schema.Notation

  @desc "A book"
  object :book do
    field :id, :id
    field :title, :string
    field :author, :string
    field :language, :string
    field :pages, list_of(:page)
  end

  @desc "A page withing a book"
  object :page do
    field :id, :id
    #    field :image, :binary
    field :image_type, :string
    field :page, :integer
    field :translations, list_of(:translation)
  end

  @desc "Translations within a page"
  object :translation do
    field :id, :id
    field :text, :string
    field :positions, list_of(:position)
  end

  @desc "Positions for translation blobs drawn on page"
  object :position do
    field :id, :id
    field :x, :integer
    field :y, :integer
    field :group, :integer
  end
end
