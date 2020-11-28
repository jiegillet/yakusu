defmodule CdcBooksWeb.Books.BookView do
  use CdcBooksWeb, :view
  alias CdcBooksWeb.Books.BookView
  alias CdcBooks.Books
  alias CdcBooks.Books.{Book, Page}

  def render("index.json", %{books: books}) do
    %{data: render_many(books, BookView, "book.json")}
  end

  def render("show.json", %{book: book}) do
    %{data: render_one(book, BookView, "book.json")}
  end

  def render("book.json", %{book: book}) do
    %{
      id: book.id,
      title: book.title,
      author: book.author,
      language: book.language,
      notes: book.notes,
      translator: book.translator
    }
  end

  def render("book.txt", %{book: %Book{original_id: id} = book, max_characters: max_characters})
      when not is_nil(id) do
    original = Books.get_book!(id)

    """
    Original book: #{original.title} by #{original.author}

    This translation was provided by #{book.translator}
    #{
      if not is_nil(book.notes) do
        "Translator notes:\n#{book.notes}\n"
      end
    }
    The following translation has been grouped by blocks of a length that can be printed in one go.
    Please copy paste individual blocks in the labeling app.
    Two spaces indicate where the tape should be cut.
    Please mind situations where you need different fonts, colors or sizes.

    ============================================================


    #{get_translation_text(book, max_characters)}
    """
  end

  defp get_translation_text(%Book{} = book, max_characters) do
    Books.list_pages(book)
    |> Enum.sort_by(& &1.page_number)
    |> Enum.map(&Books.list_translations/1)
    |> Enum.concat()
    |> Enum.map(& &1.text)
    |> Enum.map(&String.trim/1)
    |> Enum.join("\n")
    |> String.replace(~r/ +/, " ")
    |> String.split("\n")
    |> Enum.map(fn string -> [{String.length(string), string}] end)
    |> Enum.reduce(fn [{k, string}], [{n, block} | rest] ->
      if n + k + 2 <= max_characters do
        [{n + k + 2, "#{block}  #{string}"} | rest]
      else
        [{k, string} | [{n, block} | rest]]
      end
    end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.reverse()
    |> Enum.join("\n\n\n")
  end
end
