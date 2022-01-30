defmodule Mix.Tasks.LoadVaporConfig do
  @moduledoc false
  use Mix.Task

  def run(args \\ []) do
    if args == [], do: Mix.shell().info("Loading Vapor Config")

    case Paygate.AppConfig.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
