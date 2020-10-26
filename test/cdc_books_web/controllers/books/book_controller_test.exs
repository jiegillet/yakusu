defmodule CdcBooksWeb.Books.BookControllerTest do
  use CdcBooksWeb.ConnCase

  alias CdcBooks.Books
  alias CdcBooks.Books.Book

  @create_attrs %{
    author: "some author",
    language: "some language",
    notes: "some notes",
    title: "some title",
    translator: "some translator"
  }
  @update_attrs %{
    author: "some updated author",
    language: "some updated language",
    notes: "some updated notes",
    title: "some updated title",
    translator: "some updated translator"
  }
  @invalid_attrs %{author: nil, language: nil, notes: nil, title: nil, translator: nil}

  def fixture(:book) do
    {:ok, book} = Books.create_book(@create_attrs)
    book
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all books", %{conn: conn} do
      conn = get(conn, Routes.books_book_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create book" do
    test "renders book when data is valid", %{conn: conn} do
      conn = post(conn, Routes.books_book_path(conn, :create), book: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.books_book_path(conn, :show, id))

      assert %{
               "id" => id,
               "author" => "some author",
               "language" => "some language",
               "notes" => "some notes",
               "title" => "some title",
               "translator" => "some translator"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.books_book_path(conn, :create), book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update book" do
    setup [:create_book]

    test "renders book when data is valid", %{conn: conn, book: %Book{id: id} = book} do
      conn = put(conn, Routes.books_book_path(conn, :update, book), book: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.books_book_path(conn, :show, id))

      assert %{
               "id" => id,
               "author" => "some updated author",
               "language" => "some updated language",
               "notes" => "some updated notes",
               "title" => "some updated title",
               "translator" => "some updated translator"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, book: book} do
      conn = put(conn, Routes.books_book_path(conn, :update, book), book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete book" do
    setup [:create_book]

    test "deletes chosen book", %{conn: conn, book: book} do
      conn = delete(conn, Routes.books_book_path(conn, :delete, book))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.books_book_path(conn, :show, book))
      end
    end
  end

  defp create_book(_) do
    book = fixture(:book)
    %{book: book}
  end
end
