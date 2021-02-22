defmodule YakusuWeb.Books.TranslationBookController do
  use YakusuWeb, :controller

  alias Yakusu.Books
  alias Yakusu.Books.TranslationBook

  action_fallback YakusuWeb.FallbackController

  def index(conn, _params) do
    translation_books = Books.list_translation_books()
    render(conn, "index.json", translation_books: translation_books)
  end

  def create(conn, %{"translation_book" => translation_book_params}) do
    with {:ok, %TranslationBook{} = translation_book} <- Books.create_translation_book(translation_book_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.books_translation_book_path(conn, :show, translation_book))
      |> render("show.json", translation_book: translation_book)
    end
  end

  def show(conn, %{"id" => id}) do
    translation_book = Books.get_translation_book!(id)
    render(conn, "show.json", translation_book: translation_book)
  end

  def update(conn, %{"id" => id, "translation_book" => translation_book_params}) do
    translation_book = Books.get_translation_book!(id)

    with {:ok, %TranslationBook{} = translation_book} <- Books.update_translation_book(translation_book, translation_book_params) do
      render(conn, "show.json", translation_book: translation_book)
    end
  end

  def delete(conn, %{"id" => id}) do
    translation_book = Books.get_translation_book!(id)

    with {:ok, %TranslationBook{}} <- Books.delete_translation_book(translation_book) do
      send_resp(conn, :no_content, "")
    end
  end
end
