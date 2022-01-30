defmodule ConsoleTransactionResultNotificator do
  @moduledoc false

  defstruct []

  require Logger

  defimpl Types.TransactionResultNotificator do
    def execute(_this, params) do
      Logger.info(inspect(params), label: "Transaction result notice:")
    end
  end
end
