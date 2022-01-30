defmodule CircuitBreaker do
  @moduledoc false

  require Logger

  defstruct [
    :id,
    error_max: 3,
    timeout: 5
  ]

  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  @impl true
  def handle_event(
        :enter,
        :closed = _event,
        :closed = _state,
        %{
          this: _this
        } = _data
      ) do
    :keep_state_and_data
  end

  @impl true
  def handle_event(
        :enter,
        :half_open = _event,
        :closed = _state,
        %{
          this: _this
        } = _data
      ) do
    :keep_state_and_data
  end

  @impl true
  def handle_event(
        :enter,
        :closed = _event,
        :half_open = _state,
        %{
          this: _this
        } = _data
      ) do
    :keep_state_and_data
  end

  @impl true
  def handle_event(
        :enter,
        :open = _event,
        :half_open = _state,
        %{
          this: this
        } = _data
      ) do
    :persistent_term.put(this.id, %{closed: {true, nil}})

    :keep_state_and_data
  end

  @impl true
  def handle_event(
        :enter,
        :half_open = _event,
        :open = _state,
        %{
          this: this
        } = _data
      ) do
    :persistent_term.put(this.id, %{closed: {false, nil}})

    :keep_state_and_data
  end

  def handle_event(:cast, :ok, :closed, _data) do
    :keep_state_and_data
  end

  def handle_event(:cast, :ok, _, data) do
    {
      :next_state,
      :closed,
      %{data | errors: 0}
    }
  end

  def handle_event(:cast, :error, :closed, %{this: %{timeout: timeout}} = data) do
    {
      :next_state,
      :half_open,
      %{data | errors: 1},
      [
        {:state_timeout, timeout * 1_000, :refresh_timeout}
      ]
    }
  end

  def handle_event(:cast, :error, :open, %{this: %{timeout: timeout}} = _data) do
    {:keep_state_and_data,
     [
       {:state_timeout, timeout * 1_000, :refresh_timeout}
     ]}
  end

  def handle_event(
        :cast,
        :error,
        :half_open,
        %{
          errors: errors,
          this: %{
            error_max: errors,
            timeout: timeout
          }
        } = data
      ) do
    Logger.info("Circuit breaker going to 'open' state")

    {
      :next_state,
      :open,
      %{data | errors: errors + 1},
      [
        {:state_timeout, timeout * 1_000, :refresh_timeout}
      ]
    }
  end

  def handle_event(
        :cast,
        :error,
        :half_open,
        %{
          errors: errors,
          this: %{
            timeout: timeout
          }
        } = data
      ) do
    {
      :keep_state,
      %{data | errors: errors + 1},
      [
        {:state_timeout, timeout * 1_000, :refresh_timeout}
      ]
    }
  end

  def handle_event(
        :state_timeout,
        :refresh_timeout,
        :half_open,
        %{
          errors: 1
        } = data
      ) do
    Logger.info("Circuit breaker going to 'closed' state")

    {:next_state, :closed, %{data | errors: 0}}
  end

  def handle_event(
        :state_timeout,
        :refresh_timeout,
        :half_open,
        %{
          errors: errors,
          this: %{
            timeout: timeout
          }
        } = data
      ) do
    {
      :keep_state,
      %{data | errors: errors - 1},
      [
        {:state_timeout, timeout * 1_000, :refresh_timeout}
      ]
    }
  end

  def handle_event(
        :state_timeout,
        :refresh_timeout,
        :open,
        %{
          errors: errors,
          this: %{
            timeout: timeout
          }
        } = data
      ) do
    {
      :next_state,
      :half_open,
      %{data | errors: errors - 1},
      [
        {:state_timeout, timeout * 1_000, :refresh_timeout}
      ]
    }
  end

  def start_link(args) do
    :persistent_term.put(elem(args, 1).this.id, %{closed: {true, nil}})

    GenStateMachine.start_link(__MODULE__, args, name: elem(args, 1).this.id)
  end

  defimpl Types.Switch do
    def closed?(this) do
      :persistent_term.get(this.id)
      |> Map.get(:closed)
    end
  end
end
