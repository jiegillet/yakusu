defmodule Yakusu.BooksTest do
  use Yakusu.DataCase

  alias Yakusu.Books

  describe "books" do
    alias Yakusu.Books.Book

    @valid_attrs %{author: "some author", language: "some language", notes: "some notes", title: "some title", translator: "some translator"}
    @update_attrs %{author: "some updated author", language: "some updated language", notes: "some updated notes", title: "some updated title", translator: "some updated translator"}
    @invalid_attrs %{author: nil, language: nil, notes: nil, title: nil, translator: nil}

    def book_fixture(attrs \\ %{}) do
      {:ok, book} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_book()

      book
    end

    test "list_books/0 returns all books" do
      book = book_fixture()
      assert Books.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = book_fixture()
      assert Books.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      assert {:ok, %Book{} = book} = Books.create_book(@valid_attrs)
      assert book.author == "some author"
      assert book.language == "some language"
      assert book.notes == "some notes"
      assert book.title == "some title"
      assert book.translator == "some translator"
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = book_fixture()
      assert {:ok, %Book{} = book} = Books.update_book(book, @update_attrs)
      assert book.author == "some updated author"
      assert book.language == "some updated language"
      assert book.notes == "some updated notes"
      assert book.title == "some updated title"
      assert book.translator == "some updated translator"
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = book_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_book(book, @invalid_attrs)
      assert book == Books.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %Book{}} = Books.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Books.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = book_fixture()
      assert %Ecto.Changeset{} = Books.change_book(book)
    end
  end

  describe "pages" do
    alias Yakusu.Books.Page

    @valid_attrs %{image: "some image", image_type: "some image_type"}
    @update_attrs %{image: "some updated image", image_type: "some updated image_type"}
    @invalid_attrs %{image: nil, image_type: nil}

    def page_fixture(attrs \\ %{}) do
      {:ok, page} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_page()

      page
    end

    test "list_pages/0 returns all pages" do
      page = page_fixture()
      assert Books.list_pages() == [page]
    end

    test "get_page!/1 returns the page with given id" do
      page = page_fixture()
      assert Books.get_page!(page.id) == page
    end

    test "create_page/1 with valid data creates a page" do
      assert {:ok, %Page{} = page} = Books.create_page(@valid_attrs)
      assert page.image == "some image"
      assert page.image_type == "some image_type"
    end

    test "create_page/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_page(@invalid_attrs)
    end

    test "update_page/2 with valid data updates the page" do
      page = page_fixture()
      assert {:ok, %Page{} = page} = Books.update_page(page, @update_attrs)
      assert page.image == "some updated image"
      assert page.image_type == "some updated image_type"
    end

    test "update_page/2 with invalid data returns error changeset" do
      page = page_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_page(page, @invalid_attrs)
      assert page == Books.get_page!(page.id)
    end

    test "delete_page/1 deletes the page" do
      page = page_fixture()
      assert {:ok, %Page{}} = Books.delete_page(page)
      assert_raise Ecto.NoResultsError, fn -> Books.get_page!(page.id) end
    end

    test "change_page/1 returns a page changeset" do
      page = page_fixture()
      assert %Ecto.Changeset{} = Books.change_page(page)
    end
  end

  describe "translations" do
    alias Yakusu.Books.Translation

    @valid_attrs %{translation: "some translation"}
    @update_attrs %{translation: "some updated translation"}
    @invalid_attrs %{translation: nil}

    def translation_fixture(attrs \\ %{}) do
      {:ok, translation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_translation()

      translation
    end

    test "list_translations/0 returns all translations" do
      translation = translation_fixture()
      assert Books.list_translations() == [translation]
    end

    test "get_translation!/1 returns the translation with given id" do
      translation = translation_fixture()
      assert Books.get_translation!(translation.id) == translation
    end

    test "create_translation/1 with valid data creates a translation" do
      assert {:ok, %Translation{} = translation} = Books.create_translation(@valid_attrs)
      assert translation.translation == "some translation"
    end

    test "create_translation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_translation(@invalid_attrs)
    end

    test "update_translation/2 with valid data updates the translation" do
      translation = translation_fixture()
      assert {:ok, %Translation{} = translation} = Books.update_translation(translation, @update_attrs)
      assert translation.translation == "some updated translation"
    end

    test "update_translation/2 with invalid data returns error changeset" do
      translation = translation_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_translation(translation, @invalid_attrs)
      assert translation == Books.get_translation!(translation.id)
    end

    test "delete_translation/1 deletes the translation" do
      translation = translation_fixture()
      assert {:ok, %Translation{}} = Books.delete_translation(translation)
      assert_raise Ecto.NoResultsError, fn -> Books.get_translation!(translation.id) end
    end

    test "change_translation/1 returns a translation changeset" do
      translation = translation_fixture()
      assert %Ecto.Changeset{} = Books.change_translation(translation)
    end
  end

  describe "positions" do
    alias Yakusu.Books.Position

    @valid_attrs %{x: 42, y: 42}
    @update_attrs %{x: 43, y: 43}
    @invalid_attrs %{x: nil, y: nil}

    def position_fixture(attrs \\ %{}) do
      {:ok, position} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_position()

      position
    end

    test "list_positions/0 returns all positions" do
      position = position_fixture()
      assert Books.list_positions() == [position]
    end

    test "get_position!/1 returns the position with given id" do
      position = position_fixture()
      assert Books.get_position!(position.id) == position
    end

    test "create_position/1 with valid data creates a position" do
      assert {:ok, %Position{} = position} = Books.create_position(@valid_attrs)
      assert position.x == 42
      assert position.y == 42
    end

    test "create_position/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_position(@invalid_attrs)
    end

    test "update_position/2 with valid data updates the position" do
      position = position_fixture()
      assert {:ok, %Position{} = position} = Books.update_position(position, @update_attrs)
      assert position.x == 43
      assert position.y == 43
    end

    test "update_position/2 with invalid data returns error changeset" do
      position = position_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_position(position, @invalid_attrs)
      assert position == Books.get_position!(position.id)
    end

    test "delete_position/1 deletes the position" do
      position = position_fixture()
      assert {:ok, %Position{}} = Books.delete_position(position)
      assert_raise Ecto.NoResultsError, fn -> Books.get_position!(position.id) end
    end

    test "change_position/1 returns a position changeset" do
      position = position_fixture()
      assert %Ecto.Changeset{} = Books.change_position(position)
    end
  end

  describe "categories" do
    alias Yakusu.Books.Category

    @valid_attrs %{category: "some category"}
    @update_attrs %{category: "some updated category"}
    @invalid_attrs %{category: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Books.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Books.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Books.create_category(@valid_attrs)
      assert category.category == "some category"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = category} = Books.update_category(category, @update_attrs)
      assert category.category == "some updated category"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_category(category, @invalid_attrs)
      assert category == Books.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Books.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Books.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Books.change_category(category)
    end
  end

  describe "translation_books" do
    alias Yakusu.Books.TranslationBook

    @valid_attrs %{author: "some author", notes: "some notes", title: "some title", translator: "some translator"}
    @update_attrs %{author: "some updated author", notes: "some updated notes", title: "some updated title", translator: "some updated translator"}
    @invalid_attrs %{author: nil, notes: nil, title: nil, translator: nil}

    def translation_book_fixture(attrs \\ %{}) do
      {:ok, translation_book} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Books.create_translation_book()

      translation_book
    end

    test "list_translation_books/0 returns all translation_books" do
      translation_book = translation_book_fixture()
      assert Books.list_translation_books() == [translation_book]
    end

    test "get_translation_book!/1 returns the translation_book with given id" do
      translation_book = translation_book_fixture()
      assert Books.get_translation_book!(translation_book.id) == translation_book
    end

    test "create_translation_book/1 with valid data creates a translation_book" do
      assert {:ok, %TranslationBook{} = translation_book} = Books.create_translation_book(@valid_attrs)
      assert translation_book.author == "some author"
      assert translation_book.notes == "some notes"
      assert translation_book.title == "some title"
      assert translation_book.translator == "some translator"
    end

    test "create_translation_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Books.create_translation_book(@invalid_attrs)
    end

    test "update_translation_book/2 with valid data updates the translation_book" do
      translation_book = translation_book_fixture()
      assert {:ok, %TranslationBook{} = translation_book} = Books.update_translation_book(translation_book, @update_attrs)
      assert translation_book.author == "some updated author"
      assert translation_book.notes == "some updated notes"
      assert translation_book.title == "some updated title"
      assert translation_book.translator == "some updated translator"
    end

    test "update_translation_book/2 with invalid data returns error changeset" do
      translation_book = translation_book_fixture()
      assert {:error, %Ecto.Changeset{}} = Books.update_translation_book(translation_book, @invalid_attrs)
      assert translation_book == Books.get_translation_book!(translation_book.id)
    end

    test "delete_translation_book/1 deletes the translation_book" do
      translation_book = translation_book_fixture()
      assert {:ok, %TranslationBook{}} = Books.delete_translation_book(translation_book)
      assert_raise Ecto.NoResultsError, fn -> Books.get_translation_book!(translation_book.id) end
    end

    test "change_translation_book/1 returns a translation_book changeset" do
      translation_book = translation_book_fixture()
      assert %Ecto.Changeset{} = Books.change_translation_book(translation_book)
    end
  end
end
