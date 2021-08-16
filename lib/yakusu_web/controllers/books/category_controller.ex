defmodule YakusuWeb.Books.CategoryController do
  use YakusuWeb, :controller

  alias Yakusu.Books
  alias Yakusu.Books.Category

  action_fallback YakusuWeb.FallbackController

  def index(conn, _params) do
    categories = Books.list_categories()
    render(conn, "index.json", categories: categories)
  end

  def create(conn, %{"category" => category_params}) do
    with {:ok, %Category{} = category} <- Books.create_category(category_params) do
      conn
      |> put_status(:created)
      |> render("show.json", category: category)
    end
  end

  def show(conn, %{"id" => id}) do
    category = Books.get_category!(id)
    render(conn, "show.json", category: category)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Books.get_category!(id)

    with {:ok, %Category{} = category} <- Books.update_category(category, category_params) do
      render(conn, "show.json", category: category)
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Books.get_category!(id)

    with {:ok, %Category{}} <- Books.delete_category(category) do
      send_resp(conn, :no_content, "")
    end
  end
end
