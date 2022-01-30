defmodule Paygate.AppConfig.RateLimiting do
  @moduledoc false

  alias Decorators.RateLimiterTransferImpl

  def bindings do
    [
      {:rate_limiter_interval, "PAYGATE_RATE_LIMITER_INTERVAL",
       default: 5_000, map: &Paygate.AppConfig.convert!/1},
      {:rate_limiter_max_demand, "PAYGATE_RATE_LIMITER_MAX_DEMAND",
       default: 1, map: &Paygate.AppConfig.convert!/1},
      {:rate_limiter_min_demand, "PAYGATE_RATE_LIMITER_MIN_DEMAND",
       default: 0, map: &Paygate.AppConfig.convert!/1},
      {:retries_max_retries, "PAYGATE_RETRIES", default: 3, map: &Paygate.AppConfig.convert!/1},
      {:retries_backoff, "PAYGATE_RETRIES_BACKOFF",
       default: 3000, map: &Paygate.AppConfig.convert!/1}
    ]
  end

  @spec config(map(), %Structs.RateLimitingParams{}) :: %Structs.RateLimitingReturn{}
  def config(_configs, %Structs.RateLimitingParams{service: service}) do
    rate_limiter_id = :token_bucket

    transfer_root_validator0 = %RateLimiterTransferImpl{
      self: service,
      limiter: rate_limiter_id
    }

    %Structs.RateLimitingReturn{
      rate_limiter_id: rate_limiter_id,
      transfer_root_validator0: transfer_root_validator0
    }
  end
end
