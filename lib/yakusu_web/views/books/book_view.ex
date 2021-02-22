defmodule YakusuWeb.Books.BookView do
  use YakusuWeb, :view
  alias YakusuWeb.Books.BookView
  alias Yakusu.Books
  alias Yakusu.Books.{Book, Page}
  alias YakusuWeb.LanguageView

  def render("index.json", %{books: books}) do
    %{data: render_many(books, BookView, "book.json")}
  end

  def render("show.json", %{book: book}) do
    %{data: render_one(book, BookView, "book.json")}
  end

  def render("book.json", %{book: book}) do
    %{
      id: book.id,
      title: book.title,
      author: book.author,
      language: LanguageView.render("show.json", %{language: book.language})
    }
  end
end
