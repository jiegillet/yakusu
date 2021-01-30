defmodule CdcBooksWeb.Resolvers.Books do
  alias CdcBooks.Books
  alias CdcBooks.Books.{TranslationBook, Book}
  alias CdcBooks.Languages

  def list_books(_parent, _args, _resolution) do
    {:ok, Books.list_books()}
  end

  def list_pages(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_pages(book)}
  end

  def find_book(_parent, %{id: id}, _resolution) do
    {:ok, Books.get_book(id)}
  end

  def get_book(%TranslationBook{book_id: book_id}, _args, _resolution) do
    {:ok, Books.get_book(book_id)}
  end

  def find_translation_book(_parent, %{id: id}, _resolution) do
    {:ok, Books.get_translation_book(id)}
  end

  def get_language(%{language_id: language_id}, _args, _resolution) do
    {:ok, Languages.get_language!(language_id)}
  end

  def get_category(%Book{} = book, _args, _resolution) do
    {:ok, Books.get_category!(book.category_id)}
  end

  def list_book_translations(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_book_translations(book)}
  end

  def list_translations(%TranslationBook{} = book, _args, _resolution) do
    {:ok, Books.list_translations(book)}
  end

  def list_categories(_parent, _args, _resolution) do
    {:ok, Books.list_categories()}
  end

  def create_book(_parent, %{id: id} = args, _resolution) do
    Books.get_book!(id)
    |> Books.update_book(args)
  end

  def create_book(_parent, args, _resolution) do
    Books.create_book(args)
  end

  def delete_book(_parent, %{id: id}, _resolution) do
    Books.get_book!(id)
    |> Books.delete_book()
  end

  def create_translation_book(_parent, %{id: id} = args, _resolution) do
    Books.get_translation_book!(id)
    |> Books.update_translation_book(args)
  end

  def create_translation_book(_parent, args, _resolution) do
    Books.create_translation_book(args)
  end

  def delete_translation_book(_parent, %{id: id}, _resolution) do
    Books.get_translation_book!(id)
    |> Books.delete_translation_book()
  end

  def create_translation(_parent, %{translation: %{id: id} = args}, _resolution) do
    Books.get_translation!(id)
    |> Books.update_translation(args)
  end

  def create_translation(_parent, %{translation: args}, _resolution) do
    Books.create_translation(args)
  end

  def delete_translation(_parent, %{id: id}, _resolution) do
    Books.get_translation!(id)
    |> Books.delete_translation()
  end
end
