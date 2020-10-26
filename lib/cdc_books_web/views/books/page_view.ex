defmodule CdcBooksWeb.Books.PageView do
  use CdcBooksWeb, :view
  alias CdcBooksWeb.Books.PageView

  def render("index.json", %{pages: pages}) do
    %{data: render_many(pages, PageView, "page.json")}
  end

  def render("show.json", %{page: page}) do
    %{data: render_one(page, PageView, "page.json")}
  end

  def render("page.json", %{page: page}) do
    %{id: page.id,
      image: page.image,
      image_type: page.image_type}
  end
end
