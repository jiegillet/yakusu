defmodule CdcBooksWeb.Books.BookController do
  use CdcBooksWeb, :controller

  alias CdcBooks.Books
  alias CdcBooks.Books.Book
  alias CdcBooks.Repo

  action_fallback CdcBooksWeb.FallbackController

  def index(conn, _params) do
    books = Books.list_books()
    render(conn, "index.json", books: books)
  end

  def create(conn, %{"book" => book_params}) do
    with {:ok, %Book{} = book} <- Books.create_book(book_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.books_book_path(conn, :show, book))
      |> render("show.json", book: book)
    end
  end

  def show(conn, %{"id" => id}) do
    book = Books.get_book!(id)
    render(conn, "show.json", book: book)
  end

  def export(conn, %{"id" => id, "max" => max_characters}) do
    book = Books.get_book!(id)
    render(conn, "book.txt", book: book, max_characters: String.to_integer(max_characters))
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = Books.get_book!(id)

    with {:ok, %Book{} = book} <- Books.update_book(book, book_params) do
      render(conn, "show.json", book: book)
    end
  end

  def delete(conn, %{"id" => id}) do
    book = Books.get_book!(id)

    with {:ok, %Book{}} <- Books.delete_book(book) do
      send_resp(conn, :no_content, "")
    end
  end
end
