defmodule YakusuWeb.Books.TranslationView do
  use YakusuWeb, :view
  alias YakusuWeb.Books.TranslationView

  def render("index.json", %{translations: translations}) do
    %{data: render_many(translations, TranslationView, "translation.json")}
  end

  def render("show.json", %{translation: translation}) do
    %{data: render_one(translation, TranslationView, "translation.json")}
  end

  def render("translation.json", %{translation: translation}) do
    %{id: translation.id,
      translation: translation.translation}
  end
end
