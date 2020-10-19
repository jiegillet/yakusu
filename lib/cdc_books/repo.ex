defmodule CdcBooks.Repo do
  use Ecto.Repo,
    otp_app: :cdc_books,
    adapter: Ecto.Adapters.Postgres
end
