defmodule Decorators.CircuitBreakerTransferValidatorImpl do
  @moduledoc false

  defstruct [:self, :switch]

  defimpl Types.PaymentServiceTransfer do
    def execute(this, params) do
      case Types.Switch.closed?(this.switch) do
        {true, _} ->
          Types.PaymentServiceTransfer.execute(this.self, params)

        {false, _} ->
          {:error, :transfer_service_down}
      end
    end
  end
end
