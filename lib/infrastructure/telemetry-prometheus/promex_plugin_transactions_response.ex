defmodule Telemetry.PromEx.Plugins.TransactionsResponse do
  @moduledoc false

  use PromEx.Plugin

  require Logger

  @impl true
  def event_metrics(_opts) do
    # todo: put this into config to get better performance
    event_prefix = [Application.get_application(__MODULE__), :transaction, :api]

    txn_types = [:transfer]

    events_labels = [
      :too_many_requests,
      :currency_invalid,
      :service_down,
      :token_service_down,
      :unknown,
      :success
    ]

    Event.build(
      :response_transaction_event_metrics,
      for t <- txn_types,
          e <- events_labels do
        counter(
          event_prefix ++ [t, e, :response, :total],
          event_name: event_prefix ++ [t, e, :response],
          tags: [:label]
        )
      end
    )
  end
end
