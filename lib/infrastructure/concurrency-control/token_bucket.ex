defmodule RateLimiting.TokenBucket do
  @moduledoc false

  # https://github.com/dashbitco/broadway/blob/a306adb5b5a413da97a214058818cdc85aa396c4/lib/broadway/topology/rate_limiter.ex

  use GenServer

  require Logger

  defstruct [
    :refill_rate,
    :refill_time,
    :bucket_size
  ]

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    refill_rate = Keyword.fetch!(args, :refill_rate)
    refill_time = Keyword.fetch!(args, :refill_time)
    bucket_size = Keyword.fetch!(args, :bucket_size)

    GenServer.start_link(
      __MODULE__,
      %{
        bucket_count: bucket_size,
        this: %__MODULE__{
          refill_rate: refill_rate,
          refill_time: refill_time,
          bucket_size: bucket_size
        }
      },
      name: name
    )
  end

  @impl true
  def init(
        %{
          this: %__MODULE__{
            refill_rate: rate,
            refill_time: rtime
          }
        } = args
      ) do
    Process.send_after(self(), {:refill, rate}, rtime)
    {:ok, args}
  end

  @impl true
  def handle_call(:check_enough_tokens_and_consume, _from, %{bucket_count: 0} = state) do
    {:reply, {false, :not_enough_tokens_to_consume}, state}
  end

  @impl true
  def handle_call(:check_enough_tokens_and_consume, _from, %{bucket_count: bucket_count} = state) do
    {:reply, {true, nil}, %{state | bucket_count: bucket_count - 1}}
  end

  @impl true
  def handle_info(
        {:refill, amount},
        %{
          bucket_count: count,
          this: %__MODULE__{
            refill_rate: rate,
            refill_time: rtime,
            bucket_size: size
          }
        } = state
      ) do
    new_count = min(size, count + amount)

    Process.send_after(self(), {:refill, rate}, rtime)

    {:noreply, %{state | bucket_count: new_count}}
  end
end
