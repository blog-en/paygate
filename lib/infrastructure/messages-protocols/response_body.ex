defmodule ResponseBody do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:status, :content]
end
