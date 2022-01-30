defmodule TransactionErrorResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:reason, :body]
end
