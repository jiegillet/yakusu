defmodule CdcBooksWeb.Resolvers.Books do
  def list_books(_parent, _args, _resolution) do
    {:ok, CdcBooks.Books.list_books()}
  end

  def create_book(_parent, args, _resolution) do
    CdcBooks.Books.create_book(args)
  end
end
