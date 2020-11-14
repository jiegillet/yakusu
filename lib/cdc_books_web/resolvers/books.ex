defmodule CdcBooksWeb.Resolvers.Books do
  alias CdcBooks.Books
  alias CdcBooks.Books.{Book, Translation, Page}

  def list_books(_parent, _args, _resolution) do
    {:ok, Books.list_original_books()}
  end

  def list_pages(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_pages(book)}
  end

  def find_book(_parent, %{id: id}, _resolution) do
    case Books.get_book!(id) do
      nil ->
        {:error, "Book #{id} not found"}

      book ->
        {:ok, book}
    end
  end

  def list_book_translations(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_book_translations(book)}
  end

  def list_translations(%Book{} = book, _args, _resolution) do
    {:ok, Books.list_translations(book)}
  end

  #  def list_translations(%Page{} = page, _args, _resolution) do
  #    {:ok, Books.list_translations(page)}
  #  end

  def list_positions(%Translation{} = trans, _args, _resolution) do
    {:ok, Books.list_positions(trans)}
  end

  def create_book(_parent, %{id: id} = args, _resolution) do
    Books.get_book!(id)
    |> Books.update_book(args)
  end

  def create_book(_parent, args, _resolution) do
    Books.create_book(args)
  end

  def create_translation(_parent, %{translation: %{id: id, blob: blob} = args}, _resolution) do
    with {:ok, translation} <-
           Books.get_translation!(id)
           |> Books.update_translation(args),
         :ok <- create_positions(translation, blob) do
      {:ok, translation}
    end
  end

  def create_translation(_parent, %{translation: %{blob: blob} = args}, _resolution) do
    with {:ok, translation} <- Books.create_translation(args),
         :ok <- create_positions(translation, blob) do
      {:ok, translation}
    else
      err -> {:error, err}
    end
  end

  defp create_positions(%Translation{id: translation_id}, positions) do
    positions
    |> Enum.map(fn position ->
      {:ok, _position} =
        Map.put_new(position, :translation_id, translation_id)
        |> create_position()
    end)

    :ok
  end

  defp create_position(%{id: _id} = position) do
    {:ok, position}
  end

  defp create_position(position) do
    Books.create_position(position)
  end
end
