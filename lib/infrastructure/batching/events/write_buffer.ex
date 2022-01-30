defmodule Events.WriteBuffer do
  @moduledoc false

  use GenServer
  require Logger

  @default_flush_interval_ms 5_000
  @default_max_buffer_size 10_000

  defstruct [
    :writer,
    :name,
    flush_interval_ms: @default_flush_interval_ms,
    max_buffer_size: @default_max_buffer_size
  ]

  def start_link(args) do
    GenServer.start_link(
      __MODULE__,
      %{
        this: args,
        buffer_pending: [],
        buffer_finished: []
      },
      name: args.name
    )
  end

  @impl true
  def init(%{this: %{flush_interval_ms: flush_interval_ms}} = args) do
    Process.flag(:trap_exit, true)
    timer_pending = Process.send_after(self(), :tick_pending, flush_interval_ms)
    timer_finished = Process.send_after(self(), :tick_finished, flush_interval_ms)
    {:ok, Map.merge(args, %{timer_pending: timer_pending, timer_finished: timer_finished})}
  end

  @impl true
  def handle_cast(
        {{:insert, :finished}, {txn_type, params, events, {started_time, ended_time}}},
        %{
          this: %{flush_interval_ms: flush_interval_ms, max_buffer_size: max_buffer_size},
          buffer_finished: buffer_finished
        } = state
      ) do
    event = %{
      txn_type: txn_type,
      params: params,
      events: events,
      started_time: started_time,
      ended_time: ended_time
    }

    new_buffer = [event | buffer_finished]

    if length(new_buffer) >= max_buffer_size do
      Logger.info("Finished Buffer full, flushing to disk")
      Process.cancel_timer(state[:timer_finished])
      do_flush_finished(%{state | buffer_finished: new_buffer})
      new_timer = Process.send_after(self(), :tick_finished, flush_interval_ms)
      {:noreply, %{state | buffer_finished: [], timer_finished: new_timer}}
    else
      {:noreply, %{state | buffer_finished: new_buffer}}
    end
  end

  @impl true
  def handle_cast(
        {{:insert, :pending}, {txn_type, txn_state, params, events, started_time}},
        %{
          this: %{flush_interval_ms: flush_interval_ms, max_buffer_size: max_buffer_size},
          buffer_pending: buffer_pending
        } = state
      ) do
    #    Logger.error("Pending inserting: #{inspect(events)}")
    event = %{
      txn_type: txn_type,
      state: txn_state,
      params: params,
      events: events,
      started_time: started_time
    }

    new_buffer = [event | buffer_pending]

    if length(new_buffer) >= max_buffer_size do
      Logger.info("Pending Buffer full, flushing to disk")
      Process.cancel_timer(state[:timer_pending])
      do_flush_pending(%{state | buffer_pending: new_buffer})
      new_timer = Process.send_after(self(), :tick_pending, flush_interval_ms)
      {:noreply, %{state | buffer_pending: [], timer_pending: new_timer}}
    else
      {:noreply, %{state | buffer_pending: new_buffer}}
    end
  end

  @impl true
  def handle_info(
        :tick_finished,
        %{this: %{flush_interval_ms: flush_interval_ms}} = state
      ) do
    do_flush_finished(state)
    timer = Process.send_after(self(), :tick_finished, flush_interval_ms)
    {:noreply, %{state | buffer_finished: [], timer_finished: timer}}
  end

  @impl true
  def handle_info(
        :tick_pending,
        %{this: %{flush_interval_ms: flush_interval_ms}} = state
      ) do
    do_flush_pending(state)
    timer = Process.send_after(self(), :tick_pending, flush_interval_ms)
    {:noreply, %{state | buffer_pending: [], timer_pending: timer}}
  end

  @impl true
  def handle_call(
        :flush_finished,
        _from,
        %{this: %{flush_interval_ms: flush_interval_ms}} = state
      ) do
    Process.cancel_timer(state[:timer_finished])
    do_flush_finished(state)
    new_timer = Process.send_after(self(), :tick_finished, flush_interval_ms)
    {:reply, nil, %{state | buffer_pending: [], timer_finished: new_timer}}
  end

  @impl true
  def handle_call(
        :flush_pending,
        _from,
        %{this: %{flush_interval_ms: flush_interval_ms}} = state
      ) do
    Process.cancel_timer(state[:timer_pending])
    do_flush_pending(state)
    new_timer = Process.send_after(self(), :tick_pending, flush_interval_ms)
    {:reply, nil, %{state | buffer_pending: [], timer_pending: new_timer}}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.error("Flushing event buffers before shutdown...")

    #    Logger.info("Flushing event buffer_pending before shutdown...")
    #    do_flush_finished(state.buffer_finished)
    #    do_flush_pending(state.buffer_pending)

    do_flush_finished(state)
    do_flush_pending(state)
  end

  defp do_flush_finished(%{this: %{writer: writer}, buffer_finished: buffer_finised}) do
    case buffer_finised do
      [] ->
        nil

      events ->
        Logger.info("Flushing #{length(events)} finished events")
        maybe_write(writer, :finished, events)
    end
  end

  defp do_flush_pending(%{this: %{writer: writer}, buffer_pending: buffer_pending}) do
    case buffer_pending do
      [] ->
        nil

      events ->
        Logger.info("Flushing #{length(events)} pending events")
        maybe_write(writer, :pending, events)
    end
  end

  defp maybe_write(nil, _, _), do: nil

  defp maybe_write(this, :pending, events) do
    Types.PaygateRepository.insert_pending_transactions(this, events)
  end

  defp maybe_write(this, :finished, events) do
    Types.PaygateRepository.insert_finished_transactions(this, events)
  end

  defimpl Types.PaymentServiceBufferWriter do
    def insert_finished_transaction(this, txn) do
      GenServer.cast(this.name, {{:insert, :finished}, txn})
    end

    def insert_pending_transaction(this, txn) do
      GenServer.cast(this.name, {{:insert, :pending}, txn})
    end
  end
end
