defmodule Paygate.AppConfig do
  @moduledoc false

  use GenServer

  alias Vapor.Provider.{Env, Dotenv}

  require Logger

  @pt_key __MODULE__

  def child_spec(arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [arg]}}
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  defdelegate create_composition_root(configs), to: Paygate.AppConfig.Base
  defdelegate config_prom_ex(config), to: Paygate.AppConfig.PromEx

  def bindings do
    [
      {:http_port, "PAYGATE_HTTP_PORT", default: 4000, map: &String.to_integer/1},
      {
        :metrics_port,
        "PAYGATE_METRICS_SERVER_PORT",
        default: 4002, map: &String.to_integer/1
      },
      {:start_prometheus, "PAYGATE_START_PROMETHEUS", default: false, map: &convert!/1},
      {:as_component, "PAYGATE_AS_COMPONENT", default: false, map: &convert!/1},
      {:start_endpoint, "PAYGATE_START_ENDPOINT", default: true, map: &convert!/1},
      {:supervisor_shutdown_timeout, "PAYGATE_SUPERVISOR_SHUTDOWN_TIMEOUT",
       default: 25_000, map: &convert!/1}
    ]
  end

  def load_configs(starting_configs \\ %{}) do
    providers = [
      %Dotenv{overwrite: true},
      %Env{
        bindings:
          [
            Paygate.AppConfig.Persistence.bindings(),
            Paygate.AppConfig.CircuitBreaker.bindings(),
            Paygate.AppConfig.RateLimiting.bindings(),
            Paygate.AppConfig.Transfer.bindings(),
            Paygate.AppConfig.Base.bindings(),
            __MODULE__.bindings()
          ]
          |> List.flatten()
      }
    ]

    res =
      try do
        Vapor.load!(providers)
      rescue
        e in Vapor.LoadError ->
          IO.puts("Config error: #{e.message}")
          :erlang.halt(2)
      end

    res = Map.merge(res, starting_configs)

    res
    |> Map.put(:root, create_composition_root(res))
  end

  def init(arg) do
    params = Keyword.get(arg, :params, %{})
    configs = load_configs(params)
    :persistent_term.put(@pt_key, configs)
    {:ok, arg}
  end

  @doc """
  Gets the entire runtime config as a map.
  """
  def get() do
    :persistent_term.get(@pt_key)
  end

  @doc """
  Gets a value from the runtime config by `key`
  """
  def get(key) do
    :persistent_term.get(@pt_key)
    |> Map.get(key)
  end

  @doc """
  Puts the `value` for the given `key` into runtime config
  """
  def set(key, value) do
    new_config =
      :persistent_term.get(@pt_key)
      |> Map.put(key, value)

    :persistent_term.put(@pt_key, new_config)
  end

  def convert!("true"), do: true
  def convert!("false"), do: false

  def convert!(value),
    do:
      Integer.parse(value)
      |> elem(0)

  def convert_string_set!(""), do: MapSet.new([])

  def convert_string_set!(value),
    do:
      String.split(value, ",")
      |> MapSet.new()
end
