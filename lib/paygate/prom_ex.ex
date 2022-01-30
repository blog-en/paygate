defmodule Paygate.PromEx do
  @moduledoc false

  use PromEx, otp_app: :paygate

  alias PromEx.Plugins

  @impl true
  def plugins do
    if Paygate.AppConfig.get(:as_component) do
      []
    else
      [
        Plugins.Application,
        Plugins.Beam,
        Telemetry.PromEx.Plugins.Transactions,
        Telemetry.PromEx.Plugins.TransactionsResponse
      ]
    end ++ [{Plugins.Phoenix, router: PaygateWeb.Router}]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id:
        Application.fetch_env!(Application.get_application(__MODULE__), __MODULE__)[:datasource]
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"}
    ]
  end
end
