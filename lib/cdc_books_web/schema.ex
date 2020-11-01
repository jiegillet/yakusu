defmodule CdcBooksWeb.Schema do
  use Absinthe.Schema
  import_types(CdcBooksWeb.Schema.BooksTypes)

  alias CdcBooksWeb.Resolvers

  query do
    @desc "Get all books"
    field :books, list_of(:book) do
      resolve(&Resolvers.Books.list_books/3)
    end
  end

  mutation do
    @desc "Create a book"
    field :create_book, type: :book do
      arg(:title, non_null(:string))
      arg(:author, non_null(:string))
      arg(:language, non_null(:string))

      resolve(&Resolvers.Books.create_book/3)
    end
  end
end
