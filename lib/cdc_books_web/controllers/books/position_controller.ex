defmodule CdcBooksWeb.Books.PositionController do
  use CdcBooksWeb, :controller

  alias CdcBooks.Books
  alias CdcBooks.Books.Position

  action_fallback CdcBooksWeb.FallbackController

  def index(conn, _params) do
    positions = Books.list_positions()
    render(conn, "index.json", positions: positions)
  end

  def create(conn, %{"position" => position_params}) do
    with {:ok, %Position{} = position} <- Books.create_position(position_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.books_position_path(conn, :show, position))
      |> render("show.json", position: position)
    end
  end

  def show(conn, %{"id" => id}) do
    position = Books.get_position!(id)
    render(conn, "show.json", position: position)
  end

  def update(conn, %{"id" => id, "position" => position_params}) do
    position = Books.get_position!(id)

    with {:ok, %Position{} = position} <- Books.update_position(position, position_params) do
      render(conn, "show.json", position: position)
    end
  end

  def delete(conn, %{"id" => id}) do
    position = Books.get_position!(id)

    with {:ok, %Position{}} <- Books.delete_position(position) do
      send_resp(conn, :no_content, "")
    end
  end
end
