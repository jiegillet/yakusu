defmodule CdcBooksWeb.Resolvers.Languages do
  alias CdcBooks.Languages

  def list_languages(_parent, _args, _resolution) do
    {:ok, Languages.list_languages()}
  end
end
