defmodule Throttler.RateLimitterConfig do
  @moduledoc false

  require Logger

  defstruct [:restriction, :payment_service_metrics]

  def execute(this, events) do
    for {e, type} <- events do
      case Types.Restriction.check(this.restriction, {e, type}) do
        {true, _} ->
          maybe_count_service_metrics(this.payment_service_metrics, :retry, type)
          GenStateMachine.cast({:global, e}, :ready_for_request)

        {false, {message, reason}} ->
          GenStateMachine.cast({:global, e}, {message, reason})
      end
    end
  end

  def maybe_count_service_metrics(nil, _, _), do: nil

  def maybe_count_service_metrics(this, param, service) do
    Types.PaymentServiceMetrics.count(
      this,
      param,
      service
    )
  end
end
