defmodule CdcBooksWeb.Books.TranslationControllerTest do
  use CdcBooksWeb.ConnCase

  alias CdcBooks.Books
  alias CdcBooks.Books.Translation

  @create_attrs %{
    translation: "some translation"
  }
  @update_attrs %{
    translation: "some updated translation"
  }
  @invalid_attrs %{translation: nil}

  def fixture(:translation) do
    {:ok, translation} = Books.create_translation(@create_attrs)
    translation
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all translations", %{conn: conn} do
      conn = get(conn, Routes.books_translation_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create translation" do
    test "renders translation when data is valid", %{conn: conn} do
      conn = post(conn, Routes.books_translation_path(conn, :create), translation: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.books_translation_path(conn, :show, id))

      assert %{
               "id" => id,
               "translation" => "some translation"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.books_translation_path(conn, :create), translation: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update translation" do
    setup [:create_translation]

    test "renders translation when data is valid", %{conn: conn, translation: %Translation{id: id} = translation} do
      conn = put(conn, Routes.books_translation_path(conn, :update, translation), translation: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.books_translation_path(conn, :show, id))

      assert %{
               "id" => id,
               "translation" => "some updated translation"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, translation: translation} do
      conn = put(conn, Routes.books_translation_path(conn, :update, translation), translation: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete translation" do
    setup [:create_translation]

    test "deletes chosen translation", %{conn: conn, translation: translation} do
      conn = delete(conn, Routes.books_translation_path(conn, :delete, translation))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.books_translation_path(conn, :show, translation))
      end
    end
  end

  defp create_translation(_) do
    translation = fixture(:translation)
    %{translation: translation}
  end
end
