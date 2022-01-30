defmodule Infrastructure.Repository.MySQLRepository do
  @moduledoc false

  alias Paygate.Infrastructure.Repo

  require Logger
  import Ecto.Query

  defstruct []

  defimpl Types.PaygateRepository do
    def insert_finished_transactions(_this, txns) do
      Repo.insert_all(
        "transactions_history",
        for(
          txn <- txns,
          do: %{
            "id" =>
              txn.params.ref
              |> UUID.info!()
              |> Keyword.get(:binary),
            "log" => Jason.encode!(txn)
          }
        )
      )
    end

    def insert_pending_transactions(_this, txns) do
      Repo.insert_all(
        "transactions_active",
        for(txn <- txns, do: %{"txn_state" => Jason.encode!(txn)})
      )
    end

    def pop_all_pending_transactions(_this) do
      query = from(txn in "transactions_active", select: [:txn_state])

      result =
        {:ok,
         Repo.all(query)
         |> Enum.map(fn txn -> txn.txn_state end)}

      Repo.delete_all(from(txn in "transactions_active"))
      result
    end
  end
end
