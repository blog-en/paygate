defmodule Paygate.Application do
  @moduledoc false

  use Application

  alias Paygate.AppConfig

  def start(_type, _args) do
    AppConfig.start_link()

    config = AppConfig.load_configs()
    children = Paygate.ApplicationConfig.get_children(config)
    opts = [strategy: :one_for_one, name: Paygate.Supervisor, shutdown: config.supervisor_shutdown_timeout]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PaygateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
