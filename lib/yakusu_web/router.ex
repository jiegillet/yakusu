defmodule YakusuWeb.Router do
  use YakusuWeb, :router

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
      schema: YakusuWeb.Schema
  end

  scope "/api/rest", YakusuWeb do
    pipe_through :rest_api

    get "/book/:id/:max", Books.BookController, :export
    post "/pages/", Books.PageController, :compress_image
    get "/pages/all/:book_id", Books.PageController, :get_book_pages
    post "/pages/all/:book_id", Books.PageController, :create_pages
    get "/pages/:id", Books.PageController, :image
  end

  scope "/api" do
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: YakusuWeb.Schema
    forward "/", Absinthe.Plug, schema: YakusuWeb.Schema
  end

  scope "/", YakusuWeb do
    pipe_through :browser

    get "/", PageController, :index

    # All URLs get treated on the Elm side
    get "/*path", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", YakusuWeb do
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
  # live_dashboard "/dashboard", metrics: YakusuWeb.Telemetry
  # end
  # end
end
