# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Yakusu.Repo.insert!(%Yakusu.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Yakusu.Books

Yakusu.Repo.delete_all(Books.Category)

categories = [
  "My World",
  "Spring",
  "Insects",
  "Pets",
  "Lifecycle",
  "Summer",
  "Land",
  "Space",
  "Water",
  "Sea Animals",
  "Dinosaurs",
  "Food and Nutrition",
  "All About Me",
  "Fall/Trees",
  "Transportation",
  "My Family",
  "On the Farm",
  "My Community",
  "Winter",
  "Friendship",
  "Health and Safety",
  "Weather",
  "Clothes",
  "Animals"
]

categories
|> Enum.sort()
|> Enum.each(&Books.create_category(%{name: &1}))

# Adding languages
Yakusu.Repo.delete_all(Yakusu.Languages.Language)
{:ok, languages} = File.read("priv/repo/language.json")

languages
|> Jason.decode!()
|> Enum.each(fn {id, language} ->
  Yakusu.Languages.create_language(%{id: id, language: language})
end)
