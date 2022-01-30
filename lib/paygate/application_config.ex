defmodule Paygate.ApplicationConfig do
  @moduledoc false

  alias Paygate.AppConfig

  def get_general_components(acc, config) do
    [
      {
        fn ->
          {Plug.Cowboy.Drainer, refs: :all, shutdown: 20_000, drain_check_interval: 500}
        end,
        true
      },
      {
        fn ->
          Paygate.PromEx
        end,
        config.start_prometheus
      },
      {fn -> PaygateWeb.Telemetry end, true},
      {fn -> PaygateWeb.Endpoint end, config.start_endpoint}
    ] ++ acc
  end

  @components [
    "persistence",
    "components",
    "circuit_breaker",
    "rate_limiting",
    "pending_transactions_loader"
  ]

  def get_particular_components(acc, config) do
    AppConfig.config_prom_ex(config)

    (for comp <- @components do
       "lib/configs/components/#{comp}.exs"
       |> File.read!()
       |> Code.eval_string(config: config)
       |> elem(0)
     end
     |> List.flatten()) ++ acc
  end

  def get_children(config) do
    optionals =
      []
      |> get_general_components(config)
      |> get_particular_components(config)

    for {child, is_active} <- optionals, is_active, do: child.()
  end
end
