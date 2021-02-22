defmodule YakusuWeb.Schema.BooksTypes do
  use Absinthe.Schema.Notation
  alias YakusuWeb.Resolvers

  @desc "A book"
  object :book do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :author, non_null(:string)

    field :language, non_null(:language) do
      resolve(&Resolvers.Books.get_language/3)
    end

    field :category, non_null(:category) do
      resolve(&Resolvers.Books.get_category/3)
    end

    field :pages, non_null(list_of(non_null(:page))) do
      resolve(&Resolvers.Books.list_pages/3)
    end

    field :num_pages, non_null(:integer) do
      resolve(&Resolvers.Books.num_pages/3)
    end

    field :book_translations, non_null(list_of(non_null(:translation_book))) do
      resolve(&Resolvers.Books.list_book_translations/3)
    end
  end

  @desc "A book translation"
  object :translation_book do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :author, non_null(:string)

    field :book, non_null(:book) do
      resolve(&Resolvers.Books.get_book/3)
    end

    field :language, non_null(:language) do
      resolve(&Resolvers.Books.get_language/3)
    end

    field :translator, non_null(:string)
    field :notes, non_null(:string)

    field :translations, non_null(list_of(non_null(:translation))) do
      resolve(&Resolvers.Books.list_translations/3)
    end

    field :page_translations, non_null(list_of(non_null(:translation_page))) do
      resolve(&Resolvers.Books.list_page_translations/3)
    end
  end

  @desc "List of translations per page for a particular translation book"
  object :translation_page do
    field :page, non_null(:page)
    field :translations, non_null(list_of(non_null(:translation)))
  end

  @desc "A page withing a book"
  object :page do
    field :id, non_null(:id)

    field :image, non_null(:string) do
      resolve(&Resolvers.Books.image_to_url/3)
    end

    field :height, non_null(:integer)
    field :width, non_null(:integer)
    field :image_type, non_null(:string)
    field :page_number, non_null(:integer)
  end

  @desc "Translations within a page"
  object :translation do
    field :id, non_null(:id)
    field :page_id, non_null(:id)
    field :translation_book_id, non_null(:id)
    field :text, non_null(:string)
    field :path, non_null(:string)
  end

  @desc "Input type for translation"
  input_object :input_translation do
    field :id, :id
    field :page_id, non_null(:id)
    field :translation_book_id, non_null(:id)
    field :text, non_null(:string)
    field :path, non_null(:string)
  end

  @desc "A book category"
  object :category do
    field :id, non_null(:id)
    field :name, non_null(:string)
  end
end
