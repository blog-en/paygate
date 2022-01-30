defmodule TransactionFailedResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:reason, :body]
end
