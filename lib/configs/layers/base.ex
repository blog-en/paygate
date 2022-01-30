defmodule Paygate.AppConfig.Base do
  @moduledoc false

  #  use DiDecorator

  alias Decorators.CircuitBreakerTransferValidatorImpl
  alias Decorators.HttpRequestTransferValidatorImpl
  alias Throttler.RateLimitterConfig

  def bindings do
    [
      {:token_reset_delta, "PAYGATE_TOKEN_RESET_DELTA", default: 10, map: &String.to_integer/1},
      {:http_client_proxy, "PAYGATE_HTTP_CLIENT_PROXY", required: false},
      {:callback_http_client_proxy, "PAYGATE_CALLBACK_HTTP_CLIENT_PROXY", required: false},
      {
        :http_client_timeout,
        "PAYGATE_HTTP_CLIENT_TIMEOUT",
        default: 500, map: &String.to_integer/1
      },
      {:transaction_timeout, "PAYGATE_TRANSACTION_TIMEOUT",
       default: 3000, map: &Paygate.AppConfig.convert!/1},
      {:pooling_backoff, "PAYGATE_POOLING_BACKOFF",
       default: 30, map: &Paygate.AppConfig.convert!/1},
      {:currencies, "PAYGATE_ACTIVE_CURRENCIES",
       default: MapSet.new(["UGX"]), map: &Paygate.AppConfig.convert_string_set!/1},
      {:api_user, "PAYGATE_NODE_MTN_API_USER", required: true},
      {:api_key, "PAYGATE_NODE_MTN_API_KEY", required: true},
      {:base_url, "PAYGATE_NODE_MTN_BASE_URL", required: true},
      {:callback_base_url, "PAYGATE_CALLBACK_BASE_URL", required: false},
      {:callback_path, "PAYGATE_CALLBACK_PATH", required: false},
      {:target_env, "PAYGATE_NODE_MTN_TARGET_ENV", default: "sandbox"}
    ]
  end

  # @decorate di(root: __MODULE__)
  def create_composition_root(configs) do
    %{
      switch_id: switch_id,
      circuit_breaker: circuit_breaker
    } = Paygate.AppConfig.CircuitBreaker.config(configs)

    %{
      write_buffer: write_buffer,
      repository_entity: repository_entity,
      transactions_loader: transactions_loader
    } = Paygate.AppConfig.Persistence.config(configs)

    %{
      service: service,
      token_provider: token_provider,
      service_metrics: service_metrics,
      token_switch: token_switch,
      transfer_fsm_data: transfer_fsm_data
    } =
      Paygate.AppConfig.Transfer.config(configs, %Structs.TransferParams{
        switch_id: switch_id,
        write_buffer: write_buffer
      })

    %{
      rate_limiter_id: rate_limiter_id,
      transfer_root_validator0: transfer_root_validator0
    } =
      Paygate.AppConfig.RateLimiting.config(configs, %Structs.RateLimitingParams{service: service})

    __MODULE__.config(configs, %Structs.BaseParams{
      write_buffer: write_buffer,
      repository_entity: repository_entity,
      transactions_loader: transactions_loader,
      token_provider: token_provider,
      service_metrics: service_metrics,
      token_switch: token_switch,
      transfer_fsm_data: transfer_fsm_data,
      rate_limiter_id: rate_limiter_id,
      transfer_root_validator0: transfer_root_validator0,
      circuit_breaker: circuit_breaker
    })
  end

  @spec config(map(), %Structs.BaseParams{}) :: %Structs.BaseReturn{}
  def config(configs, %Structs.BaseParams{
        write_buffer: write_buffer,
        repository_entity: repository_entity,
        transactions_loader: transactions_loader,
        token_provider: transfer_token_provider,
        service_metrics: service_metrics,
        token_switch: transfer_token_switch,
        transfer_fsm_data: transfer_fsm_data,
        rate_limiter_id: rate_limiter_id,
        transfer_root_validator0: transfer_root_validator0,
        circuit_breaker: circuit_breaker
      }) do
    transfer_root_validator1 = %CircuitBreakerTransferValidatorImpl{
      self: transfer_root_validator0,
      switch: circuit_breaker
    }

    transfer_root_validator2 = %HttpRequestTransferValidatorImpl{
      self: transfer_root_validator1,
      currencies: configs.currencies
    }

    transfer_root_validator3 = %Decorators.TokenSwitchTransferValidatorImpl{
      self: transfer_root_validator2,
      switch: transfer_token_switch
    }

    r2 = %Restrictions.RateLimiter{
      limiter: rate_limiter_id,
      self: nil
    }

    circuit_breaker_restriction = %Restrictions.CircuitBreaker{
      switch: circuit_breaker,
      self: r2
    }

    r1 = %Restrictions.TransferTokenSwitch{
      switch: transfer_token_switch,
      self: circuit_breaker_restriction
    }

    rate_limiter_target_module = %RateLimitterConfig{
      restriction: r1,
      payment_service_metrics: service_metrics
    }

    %Structs.BaseReturn{
      circuit_breaker: circuit_breaker,
      transfer_service: transfer_root_validator3,
      transfer_token_provider: transfer_token_provider,
      rate_limiter_target_module: rate_limiter_target_module,
      transfer_token_switch: transfer_token_switch,
      repository_entity: repository_entity,
      buffer_writer: write_buffer,
      pending_transactions_loader: transactions_loader,
      transfer_fsm_data: transfer_fsm_data
    }
  end
end
