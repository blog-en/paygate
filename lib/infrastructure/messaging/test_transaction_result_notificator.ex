defmodule TestTransactionResultNotificator do
  @moduledoc false

  defstruct [:pid]

  require Logger

  defimpl Types.TransactionResultNotificator do
    def execute(this, params) do
      send(this.pid, {:response, params})
    end
  end
end
