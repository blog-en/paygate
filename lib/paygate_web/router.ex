defmodule PaygateWeb.Router do
  use PaygateWeb, :router

  pipeline :api do
    plug :accepts, ["json"]

    plug(OpenApiSpex.Plug.PutApiSpec, module: PaygateWeb.ApiSpec)
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/discovery" do
    pipe_through(:browser)

    get("/", OpenApiSpex.Plug.SwaggerUI, path: "/api/swagger/openapi")
  end

  scope "/api/swagger" do
    pipe_through(:api)

    get("/openapi", OpenApiSpex.Plug.RenderSpec, [])
  end

  scope "/payments", PaygateWeb do
    pipe_through :api

    post "/transfer", TransactionController, :transfer

    post "/transfer_callback/:ref", TransactionCallbacksController, :transfer_mtn_callback
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: PaygateWeb.Telemetry
    end
  end
end
