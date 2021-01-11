# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CdcBooks.Repo.insert!(%CdcBooks.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CdcBooks.Books

CdcBooks.Repo.delete_all(Books.Category)
categories = ["Transportation", "Food", "Sea", "Dinosaurs", "All about me", "Friendship"]

categories
|> Enum.each(&Books.create_category(%{name: &1}))

# Adding languages
CdcBooks.Repo.delete_all(CdcBooks.Languages.Language)
{:ok, languages} = File.read("priv/repo/language.json")

languages
|> Jason.decode!()
|> Enum.each(fn {id, language} ->
  CdcBooks.Languages.create_language(%{id: id, language: language})
end)
