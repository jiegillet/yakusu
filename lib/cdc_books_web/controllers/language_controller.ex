defmodule CdcBooksWeb.LanguageController do
  use CdcBooksWeb, :controller

  alias CdcBooks.Languages
  alias CdcBooks.Languages.Language

  action_fallback CdcBooksWeb.FallbackController

  def index(conn, _params) do
    languages = Languages.list_languages()
    render(conn, "index.json", languages: languages)
  end

  def create(conn, %{"language" => language_params}) do
    with {:ok, %Language{} = language} <- Languages.create_language(language_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.language_path(conn, :show, language))
      |> render("show.json", language: language)
    end
  end

  def show(conn, %{"id" => id}) do
    language = Languages.get_language!(id)
    render(conn, "show.json", language: language)
  end

  def update(conn, %{"id" => id, "language" => language_params}) do
    language = Languages.get_language!(id)

    with {:ok, %Language{} = language} <- Languages.update_language(language, language_params) do
      render(conn, "show.json", language: language)
    end
  end

  def delete(conn, %{"id" => id}) do
    language = Languages.get_language!(id)

    with {:ok, %Language{}} <- Languages.delete_language(language) do
      send_resp(conn, :no_content, "")
    end
  end
end
