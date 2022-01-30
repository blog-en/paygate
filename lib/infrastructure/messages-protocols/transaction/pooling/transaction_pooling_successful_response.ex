defmodule TransactionPoolingSuccessfulResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:response, :body]
end
