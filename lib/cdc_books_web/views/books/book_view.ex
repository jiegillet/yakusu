defmodule CdcBooksWeb.Books.BookView do
  use CdcBooksWeb, :view
  alias CdcBooksWeb.Books.BookView

  def render("index.json", %{books: books}) do
    %{data: render_many(books, BookView, "book.json")}
  end

  def render("show.json", %{book: book}) do
    %{data: render_one(book, BookView, "book.json")}
  end

  def render("book.json", %{book: book}) do
    %{id: book.id,
      title: book.title,
      author: book.author,
      language: book.language,
      notes: book.notes,
      translator: book.translator}
  end
end
