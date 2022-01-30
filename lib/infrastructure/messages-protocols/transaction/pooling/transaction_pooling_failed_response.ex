defmodule TransactionPoolingFailedResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:reason, :body, code: nil]
end
