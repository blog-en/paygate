defmodule Telemetry.PromEx.Plugins.Transactions do
  @moduledoc false

  use PromEx.Plugin

  require Logger

  @impl true
  def event_metrics(_opts) do
    # todo: put this into config to get better performance
    event_prefix = [Application.get_application(__MODULE__), :transaction]

    txn_types = [:transfer]

    events_labels = [
      :transaction_pooling_request,
      :transaction_request,
      :transaction_pooling_success,
      :transaction_pooling_failed,
      :transaction_pooling_error,
      :transaction_pooling_pending,
      :transaction_failed,
      :transaction_undefined,
      :transaction_error,
      :transaction_success,
      :retry
    ]

    Event.build(
      :requested_transaction_event_metrics,
      for t <- txn_types,
          e <- events_labels do
        counter(
          event_prefix ++ [t, e, :total],
          event_name: event_prefix ++ [t, e, :start],
          tags: [:label]
        )
      end
    )
  end
end
