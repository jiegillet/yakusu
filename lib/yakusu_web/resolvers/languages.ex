defmodule YakusuWeb.Resolvers.Languages do
  alias Yakusu.Languages

  def list_languages(_parent, _args, _resolution) do
    {:ok, Languages.list_languages()}
  end
end
