defmodule CdcBooksWeb.Books.PageController do
  use CdcBooksWeb, :controller

  alias CdcBooks.{Books, Repo}
  alias CdcBooks.Books.Page

  action_fallback CdcBooksWeb.FallbackController

  def index(conn, _params) do
    pages = Books.list_pages()
    render(conn, "index.json", pages: pages)
  end

  def get_book_pages(conn, %{"book_id" => book_id}) do
    pages =
      Books.get_book!(book_id)
      |> Books.list_pages()
      |> Enum.sort_by(& &1.page_number)

    render(conn, "index.json", pages: pages)
  end

  def create(conn, %{"page" => page_params}) do
    with {:ok, %Page{} = page} <- Books.create_page(page_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.books_page_path(conn, :show, page))
      |> render("show.json", page: page)
    end
  end

  def show(conn, %{"id" => id}) do
    page = Books.get_page!(id)
    render(conn, "show.json", page: page)
  end

  def update(conn, %{"id" => id, "page" => page_params}) do
    page = Books.get_page!(id)

    with {:ok, %Page{} = page} <- Books.update_page(page, page_params) do
      render(conn, "show.json", page: page)
    end
  end

  def delete(conn, %{"id" => id}) do
    page = Books.get_page!(id)

    with {:ok, %Page{}} <- Books.delete_page(page) do
      send_resp(conn, :no_content, "")
    end
  end

  def image(conn, %{"id" => id}) do
    page = Repo.get!(Page, id)

    conn
    |> put_resp_content_type(page.image_type, "utf-8")
    |> send_resp(200, page.image)
  end

  def compress_image(conn, %{"page" => page, "image" => %Plug.Upload{path: path}}) do
    page = Jason.decode!(page)

    {:ok, image} =
      path
      |> CdcBooks.Mogrify.blur_image()
      |> File.read()

    response = <<page::size(16)>> <> <<byte_size(image)::size(32)>> <> image

    send_resp(conn, :ok, response)
  end

  @default_attrs %{
    "new_pages" => [],
    "new_pages_number" => [],
    "delete_pages" => [],
    "reorder_pages" => [],
    "reorder_pages_number" => []
  }

  def create_pages(conn, attrs) do
    # name all arguments, some are optionals
    %{
      "book_id" => book_id,
      "new_pages" => new_pages,
      "new_pages_number" => new_pages_number,
      "delete_pages" => delete_pages,
      "reorder_pages" => reorder_pages,
      "reorder_pages_number" => reorder_pages_number
    } = Map.merge(@default_attrs, attrs)

    # Add new pages
    Enum.zip(new_pages, new_pages_number)
    |> Enum.each(fn {%Plug.Upload{path: path}, page_number} ->
      {:ok, image} = File.read(path)

      %{width: width, height: height} =
        path
        |> Mogrify.open()
        |> Mogrify.verbose()

      {:ok, _page} =
        Books.create_page(%{
          page_number: page_number,
          book_id: book_id,
          image: image,
          height: height,
          width: width,
          image_type: "image/jpg"
        })
    end)

    # Delete old pages
    delete_pages
    |> Enum.each(fn page_id ->
      page_id
      |> String.to_integer()
      |> Books.get_page!()
      |> Books.delete_page()
    end)

    # Reorder existing pages
    Enum.zip(reorder_pages, reorder_pages_number)
    |> Enum.each(fn {page_id, page_number} ->
      page_id
      |> String.to_integer()
      |> Books.get_page!()
      |> Books.update_page(%{page_number: String.to_integer(page_number)})
    end)

    send_resp(conn, :created, "")
  end
end
