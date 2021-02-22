defmodule YakusuWeb.Books.TranslationBookControllerTest do
  use YakusuWeb.ConnCase

  alias Yakusu.Books
  alias Yakusu.Books.TranslationBook

  @create_attrs %{
    author: "some author",
    notes: "some notes",
    title: "some title",
    translator: "some translator"
  }
  @update_attrs %{
    author: "some updated author",
    notes: "some updated notes",
    title: "some updated title",
    translator: "some updated translator"
  }
  @invalid_attrs %{author: nil, notes: nil, title: nil, translator: nil}

  def fixture(:translation_book) do
    {:ok, translation_book} = Books.create_translation_book(@create_attrs)
    translation_book
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all translation_books", %{conn: conn} do
      conn = get(conn, Routes.books_translation_book_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create translation_book" do
    test "renders translation_book when data is valid", %{conn: conn} do
      conn = post(conn, Routes.books_translation_book_path(conn, :create), translation_book: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.books_translation_book_path(conn, :show, id))

      assert %{
               "id" => id,
               "author" => "some author",
               "notes" => "some notes",
               "title" => "some title",
               "translator" => "some translator"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.books_translation_book_path(conn, :create), translation_book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update translation_book" do
    setup [:create_translation_book]

    test "renders translation_book when data is valid", %{conn: conn, translation_book: %TranslationBook{id: id} = translation_book} do
      conn = put(conn, Routes.books_translation_book_path(conn, :update, translation_book), translation_book: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.books_translation_book_path(conn, :show, id))

      assert %{
               "id" => id,
               "author" => "some updated author",
               "notes" => "some updated notes",
               "title" => "some updated title",
               "translator" => "some updated translator"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, translation_book: translation_book} do
      conn = put(conn, Routes.books_translation_book_path(conn, :update, translation_book), translation_book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete translation_book" do
    setup [:create_translation_book]

    test "deletes chosen translation_book", %{conn: conn, translation_book: translation_book} do
      conn = delete(conn, Routes.books_translation_book_path(conn, :delete, translation_book))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.books_translation_book_path(conn, :show, translation_book))
      end
    end
  end

  defp create_translation_book(_) do
    translation_book = fixture(:translation_book)
    %{translation_book: translation_book}
  end
end
