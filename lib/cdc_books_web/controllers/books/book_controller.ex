defmodule CdcBooksWeb.Books.BookController do
  use CdcBooksWeb, :controller

  alias CdcBooks.Books
  alias CdcBooks.Books.Book

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

  def new_book(conn, %{"book" => book_params, "pages" => pages}) do
    with {:ok, params} <- Jason.decode(book_params),
         {:ok, %Book{id: book_id} = book} <- Books.create_book(params),
         {:ok, _pages} <- add_pages(pages, book_id) do
      conn
      |> put_status(:created)
      |> render("show.json", book: book)
    end
  end

  defp add_pages(images, book_id) do
    pages =
      images
      |> Enum.with_index(1)
      |> Enum.map(fn {%Plug.Upload{content_type: image_type, path: path}, page_number} ->
        {:ok, image} = File.read(path)

        {:ok, _page} =
          Books.create_page(%{
            page_number: page_number,
            book_id: book_id,
            image: image,
            image_type: image_type
          })
      end)

    {:ok, pages}
  end
end
