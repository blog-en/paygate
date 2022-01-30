defmodule Decorators.HttpRequestTransferValidatorImpl do
  @moduledoc false

  defstruct [:self, :currencies]

  defimpl Types.PaymentServiceTransfer do
    def execute(this, %{currency: currency} = params) do
      if currency in this.currencies do
        Types.PaymentServiceTransfer.execute(this.self, params)
      else
        {:error, :transfer_currency_invalid}
      end
    end
  end
end
