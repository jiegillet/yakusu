defmodule Yakusu.Repo do
  use Ecto.Repo,
    otp_app: :yakusu,
    adapter: Ecto.Adapters.Postgres
end
