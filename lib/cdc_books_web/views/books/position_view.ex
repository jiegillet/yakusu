defmodule CdcBooksWeb.Books.PositionView do
  use CdcBooksWeb, :view
  alias CdcBooksWeb.Books.PositionView

  def render("index.json", %{positions: positions}) do
    %{data: render_many(positions, PositionView, "position.json")}
  end

  def render("show.json", %{position: position}) do
    %{data: render_one(position, PositionView, "position.json")}
  end

  def render("position.json", %{position: position}) do
    %{id: position.id,
      x: position.x,
      y: position.y}
  end
end
