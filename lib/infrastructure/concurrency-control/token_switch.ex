defmodule TokenSwitch do
  @moduledoc false

  use GenServer

  defstruct [:id]

  require Logger

  def start_link(args) do
    this = Keyword.fetch!(args, :this)
    name = this.id

    :persistent_term.put(this.id, %{closed: {false, :system_starting}})

    GenServer.start_link(
      __MODULE__,
      %{closed: false, this: this, token_service_up: false},
      name: name
    )
  end

  @impl true
  def init(args) do
    {:ok, args}
  end

  @impl true
  def handle_cast(:token_service_down = msg, %{closed: true, this: %{id: id}} = state) do
    :persistent_term.put(id, %{closed: {false, msg}})
    {:noreply, Map.merge(state, %{closed: false, token_service_up: false})}
  end

  @impl true
  def handle_cast(:token_service_down, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:token_service_up, %{closed: _status, this: %{id: id}} = state) do
    :persistent_term.put(id, %{closed: {true, nil}})
    {:noreply, Map.merge(state, %{closed: true, token_service_up: true})}
  end

  defimpl Types.Switch do
    def closed?(this) do
      :persistent_term.get(this.id)
      |> Map.get(:closed)
    end
  end
end
