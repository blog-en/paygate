defmodule TransactionSuccessfulResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:extra_info, :body]
end
