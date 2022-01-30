defmodule Paygate.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Paygate.Supervisor]
    Supervisor.start_link([], opts)
  end

  def config_change(changed, _new, removed) do
    PaygateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
