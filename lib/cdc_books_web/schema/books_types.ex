defmodule CdcBooksWeb.Schema.BooksTypes do
  use Absinthe.Schema.Notation
  alias CdcBooksWeb.Resolvers

  @desc "A book"
  object :book do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :author, non_null(:string)
    field :language, non_null(:string)
    field :translator, :string
    field :notes, :string

    field :pages, non_null(list_of(non_null(:page))) do
      resolve(&Resolvers.Books.list_pages/3)
    end

    field :book_translations, non_null(list_of(non_null(:book))) do
      resolve(&Resolvers.Books.list_book_translations/3)
    end

    field :translations, non_null(list_of(non_null(:translation))) do
      resolve(&Resolvers.Books.list_translations/3)
    end
  end

  @desc "A page withing a book"
  object :page do
    field :id, non_null(:id)
    field :image_type, non_null(:string)
    field :page_number, non_null(:integer)
  end

  @desc "Translations within a page"
  object :translation do
    field :id, non_null(:id)
    field :page_id, non_null(:id)
    field :book_id, non_null(:id)
    field :text, non_null(:string)

    field :positions, non_null(list_of(non_null(:position))) do
      resolve(&Resolvers.Books.list_positions/3)
    end
  end

  @desc "Input type for translation"
  input_object :input_translation do
    field :id, :id
    field :page_id, non_null(:id)
    field :book_id, non_null(:id)
    field :text, non_null(:string)
    field :blob, non_null(list_of(non_null(:input_position)))
  end

  @desc "Positions for translation blobs drawn on page"
  object :position do
    field :id, non_null(:id)
    field :x, non_null(:integer)
    field :y, non_null(:integer)
    field :group, non_null(:integer)
  end

  @desc "Input type for position"
  input_object :input_position do
    field :id, :id
    field :x, non_null(:integer)
    field :y, non_null(:integer)
    field :group, non_null(:integer)
  end
end
