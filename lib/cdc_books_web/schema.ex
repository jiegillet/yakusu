defmodule CdcBooksWeb.Schema do
  use Absinthe.Schema
  import_types(CdcBooksWeb.Schema.BooksTypes)
  import_types(CdcBooksWeb.Schema.LanguagesTypes)
  import_types(Absinthe.Plug.Types)

  alias CdcBooksWeb.Resolvers

  query do
    @desc "Get all books"
    field :books, non_null(list_of(non_null(:book))) do
      resolve(&Resolvers.Books.list_books/3)
    end

    @desc "Get a particular book"
    field :book, :book do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Books.find_book/3)
    end

    @desc "Get a particular translation book"
    field :translation_book, :translation_book do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Books.find_translation_book/3)
    end

    @desc "Get all categories"
    field :categories, non_null(list_of(non_null(:category))) do
      resolve(&Resolvers.Books.list_categories/3)
    end

    @desc "Get all languages"
    field :languages, non_null(list_of(non_null(:language))) do
      resolve(&Resolvers.Languages.list_languages/3)
    end
  end

  mutation do
    @desc "Create new book translation"
    field :create_book, type: non_null(:translation_book) do
      arg(:id, :id)
      arg(:book_id, non_null(:id))
      arg(:title, non_null(:string))
      arg(:author, non_null(:string))
      arg(:language_id, non_null(:string))
      arg(:translator, non_null(:string))
      arg(:notes, :string)

      resolve(&Resolvers.Books.create_translation_book/3)
    end

    @desc "Create a page translation"
    field :create_translation, type: :translation do
      arg(:translation, non_null(:input_translation))
      resolve(&Resolvers.Books.create_translation/3)
    end

    @desc "Deletes a translation"
    field :delete_translation, type: :translation do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Books.delete_translation/3)
    end
  end
end
