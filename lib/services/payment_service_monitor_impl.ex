defmodule PaymentServiceMonitorImpl do
  @moduledoc false

  defstruct [
    :monitor_id
  ]

  defimpl Types.PaymentServiceMonitor do
    def notify(this, {msg, _} = _params) do
      GenStateMachine.cast(this.monitor_id, msg)
    end
  end
end
