defmodule YakusuWeb.Books.PageControllerTest do
  use YakusuWeb.ConnCase

  alias Yakusu.Books
  alias Yakusu.Books.Page

  @create_attrs %{
    image: "some image",
    image_type: "some image_type"
  }
  @update_attrs %{
    image: "some updated image",
    image_type: "some updated image_type"
  }
  @invalid_attrs %{image: nil, image_type: nil}

  def fixture(:page) do
    {:ok, page} = Books.create_page(@create_attrs)
    page
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all pages", %{conn: conn} do
      conn = get(conn, Routes.books_page_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create page" do
    test "renders page when data is valid", %{conn: conn} do
      conn = post(conn, Routes.books_page_path(conn, :create), page: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.books_page_path(conn, :show, id))

      assert %{
               "id" => id,
               "image" => "some image",
               "image_type" => "some image_type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.books_page_path(conn, :create), page: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update page" do
    setup [:create_page]

    test "renders page when data is valid", %{conn: conn, page: %Page{id: id} = page} do
      conn = put(conn, Routes.books_page_path(conn, :update, page), page: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.books_page_path(conn, :show, id))

      assert %{
               "id" => id,
               "image" => "some updated image",
               "image_type" => "some updated image_type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, page: page} do
      conn = put(conn, Routes.books_page_path(conn, :update, page), page: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete page" do
    setup [:create_page]

    test "deletes chosen page", %{conn: conn, page: page} do
      conn = delete(conn, Routes.books_page_path(conn, :delete, page))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.books_page_path(conn, :show, page))
      end
    end
  end

  defp create_page(_) do
    page = fixture(:page)
    %{page: page}
  end
end
