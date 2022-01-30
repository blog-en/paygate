defmodule Infrastructure.Repository.MemoryRepository do
  @moduledoc false

  use GenServer

  require Logger

  defstruct [
    :name
  ]

  def start_link(args) do
    GenServer.start_link(
      __MODULE__,
      nil,
      name: args.name
    )
  end

  @impl true
  def handle_cast({:insert_finished_transactions, txns}, %{finished: finished} = state) do
    {:noreply, %{state | finished: txns ++ finished}}
  end

  @impl true
  def handle_cast({:insert_pending_transactions, txns}, %{pending: pending} = state) do
    {:noreply, %{state | pending: txns ++ pending}}
  end

  @impl true
  def handle_call(:pop_all_pending_transactions, _from, %{pending: pending} = state) do
    {:reply, pending, %{state | pending: []}}
  end

  @file_repository "memory_repository"
  @file_repository_pending "#{@file_repository}_pending.json"
  @file_repository_finished "#{@file_repository}_finished.json"

  @impl true
  def init(_args) do
    Process.flag(:trap_exit, true)

    pending =
      if File.exists?(@file_repository_pending) do
        res =
          @file_repository_pending
          |> File.read!()
          |> Jason.decode!()

        File.rm(@file_repository_pending)

        #        Logger.error("Loading: #{inspect(res)}")

        res
        #        for {key, val} <- res, into: %{}, do: {String.to_atom(key), val}
      else
        []
      end

    {:ok, %{pending: pending, finished: []}}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.error("Saving: #{inspect(state)}")

    @file_repository_pending
    |> File.write!(Jason.encode!(state.pending))

    @file_repository_finished
    |> File.write!(Jason.encode!(state.finished))
  end

  defimpl Types.PaygateRepository do
    def insert_finished_transactions(this, txns) do
      GenServer.cast(this.name, {:insert_finished_transactions, txns})
    end

    def insert_pending_transactions(this, txns) do
      GenServer.cast(this.name, {:insert_pending_transactions, txns})
    end

    def pop_all_pending_transactions(this) do
      {:ok, GenServer.call(this.name, :pop_all_pending_transactions)}
    end
  end
end
