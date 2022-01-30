defmodule TokenSwitchNotificator do
  @moduledoc false

  defstruct [:switch]

  defimpl Types.StatusNotificator do
    def notify(this, {msg, _} = _params) do
      GenServer.cast(this.switch.id, msg)
    end
  end
end
