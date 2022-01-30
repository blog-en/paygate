defmodule GeneralResponse do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:type, :body]
end
