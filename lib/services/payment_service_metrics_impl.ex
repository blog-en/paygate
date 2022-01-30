defmodule PaymentServiceMetricsImpl do
  @moduledoc false

  defstruct service: nil

  require Logger

  defimpl Types.PaymentServiceMetrics do
    def count(this, label) do
      # todo: put this into config to get better performance
      event_prefix = [Application.get_application(__MODULE__), :transaction]

      :telemetry.execute(event_prefix ++ [this.service, label, :start], %{count: 1}, %{
        label: "active"
      })
    end

    def count(_this, label, service) do
      # todo: put this into config to get better performance
      event_prefix = [Application.get_application(__MODULE__), :transaction]

      :telemetry.execute(event_prefix ++ [service, label, :start], %{count: 1}, %{label: "active"})
    end
  end
end
