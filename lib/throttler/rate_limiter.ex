defmodule Throttler.RateLimiter do
  @moduledoc false

  use GenStage

  require Logger

  def start_link(args) do
    args = Enum.into(args, %{})
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    sub_opts = [
      {
        Throttler.Producer,
        # By default consumes 1 event every 5s
        #        max_retries: Map.get(args, :rate_limiter_max_retries, 3),
        min_demand: Map.get(args, :min_demand, 0),
        max_demand: Map.get(args, :max_demand, 1),
        interval: Map.get(args, :interval, 5_000),
        target_module: Map.fetch!(args, :target_module)
      }
    ]

    {:consumer, args, subscribe_to: sub_opts}
  end

  def handle_subscribe(:producer, opts, from, args) do
    pending = opts[:max_demand]
    interval = args[:interval]

    new_state =
      Map.new()
      |> Map.put(from, {pending, interval})
      |> Map.merge(args)
      |> ask_and_schedule(from)

    # Returns manual as we want control over the demand
    {:manual, new_state}
  end

  def handle_cancel(_, from, state) do
    # Remove the producers from the map on unsubscribe
    {:noreply, [], Map.delete(state, from)}
  end

  def handle_events(events, from, %{target_module: module} = state) do
    # Bump the amount of pending events for the given producer
    state =
      Map.update!(
        state,
        from,
        fn {pending, interval} ->
          {pending + length(events), interval}
        end
      )

    # Consume the event.
    Throttler.RateLimitterConfig.execute(module, events)

    {:noreply, [], state}
  end

  def handle_info({:ask, from}, state), do: {:noreply, [], ask_and_schedule(state, from)}

  defp ask_and_schedule(state, from) do
    case state do
      %{^from => {pending, interval}} ->
        # Ask for any pending events
        GenStage.ask(from, pending)
        # And let's check again after interval
        Process.send_after(self(), {:ask, from}, interval)
        # Finally, reset pending events to 0
        Map.put(state, from, {0, interval})

      %{} ->
        state
    end
  end
end
