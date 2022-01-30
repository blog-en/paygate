defmodule Paygate.Infrastructure.Repo do
  use Ecto.Repo,
    otp_app: :paygate,
    adapter: Ecto.Adapters.MyXQL

  def init(_arg, config) do
    config =
      config
      |> Keyword.put(:url, Paygate.AppConfig.get(:database_url))

    {:ok, config}
  end
end
