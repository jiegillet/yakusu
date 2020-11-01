defmodule CdcBooks.Books.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :text, :string
    field :page_id, :id

#    belongs_to :translations, CdcBooks.Books.Translation
#    has_many :positions, CdcBooks.Books.Position

    timestamps()
  end

  @doc false
  def changeset(translation, attrs) do
    translation
    |> cast(attrs, [:translation])
    |> validate_required([:translation])
  end
end
