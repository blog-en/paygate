defmodule PendingTransactionsLoader do
  @moduledoc false

  use GenServer

  require Logger

  defstruct [
    :name,
    :repository
  ]

  def start_link(args) do
    GenServer.start_link(
      __MODULE__,
      args,
      name: args.name
    )
  end

  @impl true
  def init(args) do
    {:ok, args, {:continue, :load_pending_transactions}}
  end

  @impl true
  def handle_continue(
        :load_pending_transactions,
        %{
          repository: repository
        } = state
      ) do
    {:ok, txns} = Types.PaygateRepository.pop_all_pending_transactions(repository)

    states_atoms = [
      "retry_needed",
      "waiting_for_callback",
      "error_state",
      "ok_state",
      "waiting_for_throttling",
      "ready_for_request"
    ]

    # atoms setup
    for st <- states_atoms, do: _ = String.to_atom(st)

    for %{
          "txn_type" => "transfer",
          "state" => state,
          "params" => params,
          "events" => messages,
          "started_time" => started_time
        } = _txn <- txns do
      Transactor.start_job({
        String.to_atom(state),
        %{
          ref: nil,
          pooling_ref: nil,
          final_message: nil,
          this: Paygate.AppConfig.get(:root).transfer_fsm_data,
          params: Ex.Utils.atomize_map_keys(params),
          messages: messages,
          started_time: started_time,
          restarting: true,
          retries: 0,
          transaction_type: :transfer
        }
      })
    end

    {:stop, :normal, state}
  end
end
