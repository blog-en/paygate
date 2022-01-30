defmodule Decorators.RateLimiterTransferImpl do
  @moduledoc false

  defstruct [:self, :limiter]

  defimpl Types.PaymentServiceTransfer do
    def execute(this, params) do
      case GenServer.call(this.limiter, :check_enough_tokens_and_consume) do
        {true, _} -> Types.PaymentServiceTransfer.execute(this.self, params)
        _ -> {:error, :too_many_requests}
      end
    end
  end
end
