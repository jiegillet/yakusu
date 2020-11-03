defmodule CdcBooksWeb.Router do
  use CdcBooksWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
      pass: ["*/*"],
      json_decoder: Jason

    plug Absinthe.Plug,
      schema: CdcBooksWeb.Schema
  end

  scope "/api/rest", CdcBooksWeb do
    pipe_through :rest_api

    post "/books", Books.BookController, :new_book 
    get "/pages/:id", Books.PageController, :image
    # post "/pages", Books.PageController, :create
    # resources "/translations", Books.TranslationController
    # resources "/positions", Books.PositionController
  end

  scope "/api" do
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: CdcBooksWeb.Schema
    forward "/", Absinthe.Plug, schema: CdcBooksWeb.Schema
  end

  scope "/", CdcBooksWeb do
    pipe_through :browser

    get "/", PageController, :index

    # All URLs get treated on the Elm side
    get "/*path", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CdcBooksWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  # if Mix.env() in [:dev, :test] do
  # import Phoenix.LiveDashboard.Router

  # scope "/" do
  #  pipe_through :browser
  # live_dashboard "/dashboard", metrics: CdcBooksWeb.Telemetry
  # end
  # end
end
