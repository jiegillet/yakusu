defmodule YakusuWeb.Books.PageView do
  use YakusuWeb, :view
  alias YakusuWeb.Books.PageView

  def render("index.json", %{pages: pages}) do
    %{data: render_many(pages, PageView, "page.json")}
  end

  def render("show.json", %{page: page}) do
    %{data: render_one(page, PageView, "page.json")}
  end

  def render("page.json", %{page: page}) do
    %{
      id: page.id,
      image: "data:" <> page.image_type <> ";base64," <> Elixir.Base.encode64(page.image),
      page_number: page.page_number,
      image_type: page.image_type
    }
  end
end
