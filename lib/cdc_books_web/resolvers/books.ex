defmodule CdcBooksWeb.Resolvers.Books do
  alias CdcBooks.Books
  alias CdcBooks.Books.Book

  def list_books(_parent, _args, _resolution) do
    {:ok, Books.list_original_books()}
  end

  def list_pages(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_pages(book)}
  end

  def find_book(_parent, %{id: id}, _resolution) do
    case Books.get_book!(id) do
      nil ->
        {:error, "Book #{id} not found"}

      book ->
        {:ok, book}
    end
  end

  def list_book_translations(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_book_translations(book)}
  end

  def list_translations(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_translations(book)}
  end

  def create_book(_parent, %{id: id} = args, _resolution) do
    Books.get_book!(id)
    |> Books.update_book(args)
  end

  def create_book(_parent, args, _resolution) do
    Books.create_book(args)
  end

  def create_translation(_parent, %{translation: %{id: id} = args}, _resolution) do
    Books.get_translation!(id)
    |> Books.update_translation(args)
  end

  def create_translation(_parent, %{translation: args}, _resolution) do
    Books.create_translation(args)
  end
end
