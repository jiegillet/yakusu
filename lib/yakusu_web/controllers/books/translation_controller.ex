defmodule YakusuWeb.Books.TranslationController do
  use YakusuWeb, :controller

  alias Yakusu.Books
  alias Yakusu.Books.Translation

  action_fallback YakusuWeb.FallbackController

  def index(conn, _params) do
    translations = Books.list_translations()
    render(conn, "index.json", translations: translations)
  end

  def create(conn, %{"translation" => translation_params}) do
    with {:ok, %Translation{} = translation} <- Books.create_translation(translation_params) do
      conn
      |> put_status(:created)
      |> render("show.json", translation: translation)
    end
  end

  def show(conn, %{"id" => id}) do
    translation = Books.get_translation!(id)
    render(conn, "show.json", translation: translation)
  end

  def update(conn, %{"id" => id, "translation" => translation_params}) do
    translation = Books.get_translation!(id)

    with {:ok, %Translation{} = translation} <- Books.update_translation(translation, translation_params) do
      render(conn, "show.json", translation: translation)
    end
  end

  def delete(conn, %{"id" => id}) do
    translation = Books.get_translation!(id)

    with {:ok, %Translation{}} <- Books.delete_translation(translation) do
      send_resp(conn, :no_content, "")
    end
  end
end
