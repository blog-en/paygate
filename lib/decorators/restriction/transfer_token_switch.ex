defmodule Restrictions.TransferTokenSwitch do
  @moduledoc false

  defstruct [:switch, self: nil]

  defimpl Types.Restriction do
    def check(nil, _) do
      {true, nil}
    end

    def check(this, {_, :transfer} = params) do
      case Types.Switch.closed?(this.switch) do
        {true, _} ->
          Types.Restriction.check(this.self, params)

        {false, reason} ->
          {false, {:cancel, reason}}
      end
    end
  end
end
