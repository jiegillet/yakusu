defmodule YakusuWeb.Books.TranslationBookView do
  use YakusuWeb, :view
  alias YakusuWeb.Books.TranslationBookView
  alias Yakusu.Books.TranslationBook
  alias Yakusu.Books

  def render("index.json", %{translation_books: translation_books}) do
    %{data: render_many(translation_books, TranslationBookView, "translation_book.json")}
  end

  def render("show.json", %{translation_book: translation_book}) do
    %{data: render_one(translation_book, TranslationBookView, "translation_book.json")}
  end

  def render("translation_book.json", %{translation_book: translation_book}) do
    %{
      id: translation_book.id,
      title: translation_book.title,
      author: translation_book.author,
      notes: translation_book.notes,
      translator: translation_book.translator
    }
  end

  def render("book.txt", %{
        translation_book: %TranslationBook{book_id: book_id} = book,
        max_characters: max_characters
      }) do
    original = Books.get_book!(book_id)

    """
    Original book: #{original.title} by #{original.author}

    Translation: #{book.title} by #{book.author}

    This translation was provided by #{book.translator}
    #{
      if not is_nil(book.notes) do
        "Translator notes:\n#{book.notes}\n"
      end
    }
    The following translation has been grouped by blocks of a length that can be printed in one go.
    Please copy paste individual blocks in the labeling app.
    Two spaces indicate where the tape should be cut.

    ============================================================


    #{get_translation_text(book, max_characters)}
    """
  end

  defp get_translation_text(%TranslationBook{} = book, max_characters) do
    Books.get_book!(book.book_id)
    |> Books.list_pages()
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
