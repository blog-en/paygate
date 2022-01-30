defmodule Restrictions.RateLimiter do
  @moduledoc false

  defstruct [:limiter, self: nil]

  defimpl Types.Restriction do
    def check(nil, _) do
      {true, nil}
    end

    def check(this, params) do
      case GenServer.call(this.limiter, :check_enough_tokens_and_consume) do
        {true, _} ->
          Types.Restriction.check(this.self, params)

        {false, reason} ->
          {false, {:retry_queue, reason}}
      end
    end
  end
end
