defmodule Paygate.AppConfig.CircuitBreaker do
  @moduledoc false

  def bindings do
    [
      {:circuit_breaker_timeout, "PAYGATE_CIRCUIT_BREAKER_TIMEOUT",
       default: 60, map: &String.to_integer/1},
      {:circuit_breaker_error_max, "PAYGATE_CIRCUIT_BREAKER_ERROR_MAX",
       default: 5, map: &String.to_integer/1},
      {:refill_rate, "PAYGATE_REFILL_RATE", default: 3, map: &Paygate.AppConfig.convert!/1},
      {:refill_time, "PAYGATE_REFILL_TIME", default: 60, map: &Paygate.AppConfig.convert!/1},
      {:bucket_size, "PAYGATE_BUCKET_SIZE", default: 3, map: &Paygate.AppConfig.convert!/1}
    ]
  end

  @spec config(map()) :: %Structs.CircuitBreakerReturn{}
  def config(configs) do
    switch_id = :switch

    circuit_breaker = %CircuitBreaker{
      id: switch_id,
      timeout: configs.circuit_breaker_timeout,
      error_max: configs.circuit_breaker_error_max - 1
    }

    %Structs.CircuitBreakerReturn{
      switch_id: switch_id,
      circuit_breaker: circuit_breaker
    }
  end
end
