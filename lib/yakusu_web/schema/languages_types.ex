defmodule YakusuWeb.Schema.LanguagesTypes do
  use Absinthe.Schema.Notation

  @desc "Language"
  object :language do
    field :id, non_null(:string)
    field :language, non_null(:string)
  end
end
