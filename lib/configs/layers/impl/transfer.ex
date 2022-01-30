defmodule Paygate.AppConfig.Transfer do
  @moduledoc false

  alias Decorators.HttpRequestParamsTokenSetter

  def bindings do
    [
      {:disbursement_subscription_key, "PAYGATE_NODE_MTN_DISBURSEMENT_SUBSCRIPTION_KEY",
       required: true},
      {
        :transfer_callback_url,
        "PAYGATE_TRANSFER_CALLBACK_URL",
        default: "http://localhost:8010/payments/transfer_callback"
      }
    ]
  end

  @spec config(map(), %Structs.TransferParams{}) :: %Structs.TransferReturn{}
  def config(
        configs,
        %Structs.TransferParams{
          switch_id: switch_id,
          write_buffer: write_buffer
        }
      ) do
    monitor = %PaymentServiceMonitorImpl{
      monitor_id: switch_id
    }

    token_http_request = %HTTPoisonRequest{
      options: [
        recv_timeout: configs.http_client_timeout,
        proxy: configs.http_client_proxy
      ],
      base_url: configs.base_url,
      path: "/disbursement/token/"
    }

    token_request_params_formater = %MTNTokenRequestParamsFormater{
      subscription_key: configs.disbursement_subscription_key,
      api_user: configs.api_user,
      api_key: configs.api_key
    }

    token_http_response = %MTNTokenHTTPoisonResponse{}

    token_switch = %TokenSwitch{id: :transfer_token_switch}

    token_provider_notificator = %TokenSwitchNotificator{
      switch: token_switch
    }

    token_provider = %MTNTokenProvider{
      id: "transfer_token_provider",
      http_request_processor: token_http_request,
      http_response_processor: token_http_response,
      params_formater: token_request_params_formater,
      notificator: token_provider_notificator,
      reset_delta: configs.token_reset_delta
    }

    http_request = %HTTPoisonRequest{
      options: [
        recv_timeout: configs.http_client_timeout,
        proxy: configs.http_client_proxy
      ],
      base_url: configs.base_url,
      path: "/disbursement/v1_0/transfer"
    }

    pooling_http_request = %HTTPoisonGetRequest{
      options: [
        recv_timeout: configs.http_client_timeout,
        proxy: configs.http_client_proxy
      ],
      base_url: configs.base_url,
      path: fn prms -> "/disbursement/v1_0/transfer/#{prms.ref}" end
    }

    pooling_http_response = %MTNTransferPoolingHTTPoisonResponse{}
    pooling_params_formater_clean = %MTNTransferPoolingRequestParamsFormater{}

    pooling_params_formater = %HttpRequestParamsTokenSetter{
      self: pooling_params_formater_clean,
      token_provider: token_provider
    }

    http_response = %MTNTransferHTTPoisonResponse{}

    request_params_formater_clean = %MTNTransferRequestParamsFormater{
      target_env: configs.target_env,
      subscription_key: configs.disbursement_subscription_key,
      callback_url: configs.transfer_callback_url
    }

    request_params_formater = %HttpRequestParamsTokenSetter{
      self: request_params_formater_clean,
      token_provider: token_provider
    }

    service_metrics = %PaymentServiceMetricsImpl{
      service: :transfer
    }

    notificator_params_formater = %CallbackRequestParamsFormater{token: "xxx"}

    notificator_request_processor = %HTTPoisonRequest{
      options: [
        recv_timeout: configs.http_client_timeout,
        proxy: configs.callback_http_client_proxy
      ],
      base_url: configs.callback_base_url,
      path: configs.callback_path
    }

    notificator =
      if Map.has_key?(configs, :notificator) do
        configs.notificator
      else
        %HTTPTransactionResultNotificator{
          params_formater: notificator_params_formater,
          http_request_processor: notificator_request_processor
        }
      end

    fsm_data = %TransactionRequesterFSM{
      pooling_params_formater: pooling_params_formater,
      pooling_http_request_processor: pooling_http_request,
      pooling_http_response_processor: pooling_http_response,
      http_request_processor: http_request,
      http_response_processor: http_response,
      params_formater: request_params_formater,
      max_retries: configs.retries_max_retries,
      backoff: configs.retries_backoff,
      transaction_timeout: configs.transaction_timeout,
      pooling_backoff: configs.pooling_backoff,
      error_callback: notificator,
      ok_callback: notificator,
      #      error_callback: %ConsoleTransactionResultNotificator{},
      #      ok_callback: %ConsoleTransactionResultNotificator{},
      payment_service_monitor: monitor,
      payment_service_metrics: service_metrics,
      payment_service_buffer_writer: write_buffer
    }

    root = %PaymentServiceTransferImpl{
      fsm_data: fsm_data
    }

    %Structs.TransferReturn{
      service: root,
      token_provider: token_provider,
      service_metrics: service_metrics,
      token_switch: token_switch,
      transfer_fsm_data: fsm_data
    }
  end
end
