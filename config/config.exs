# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :cdc_books,
  ecto_repos: [CdcBooks.Repo]

# Configures the endpoint
config :cdc_books, CdcBooksWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pQHS1CoM56WDUu6DMFaI0tFEBOYinlF572xlq6/OAf/0AdfbCTY+Wn8M7yrQ2rsg",
  render_errors: [view: CdcBooksWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: CdcBooks.PubSub,
  live_view: [signing_salt: "2TeXQ5gS"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
