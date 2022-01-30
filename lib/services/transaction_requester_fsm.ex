defmodule TransactionRequesterFSM do
  @moduledoc false

  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]
  require Logger

  defstruct [
    :params_formater,
    :http_request_processor,
    :http_response_processor,
    :pooling_params_formater,
    :pooling_http_request_processor,
    :pooling_http_response_processor,
    :max_retries,
    # retry backoff
    :backoff,
    :transaction_timeout,
    pooling_backoff: 30,
    ok_callback: nil,
    error_callback: nil,
    payment_service_monitor: nil,
    payment_service_metrics: nil,
    payment_service_buffer_writer: nil
  ]

  def handle_event(
        :info,
        {_ref, %TransactionPoolingSuccessfulResponse{} = response},
        _state,
        %{
          pooling_ref: __ref,
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_pooling_success)

    {:next_state, :ok_state, %{data | messages: [response | messages]}}
  end

  def handle_event(
        :info,
        {_ref, %TransactionPoolingFailedResponse{reason: reason} = response},
        _state,
        %{
          pooling_ref: __ref,
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_pooling_failed)

    {:next_state, :error_state, %{data | final_message: reason, messages: [response | messages]}}
  end

  def handle_event(
        :info,
        {_ref, %TransactionPoolingErrorResponse{}},
        _state,
        %{
          params: %{
            ref: id
          },
          this: %{
            pooling_backoff: pooling_backoff,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = _data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:error, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_pooling_error)

    {:keep_state_and_data,
     [
       {:state_timeout, pooling_backoff * 1_000, :pooling_timeout}
     ]}
  end

  def handle_event(
        :info,
        {_ref, %TransactionPoolingPendingResponse{}},
        _state,
        %{
          params: %{
            ref: id
          },
          this: %{
            pooling_backoff: pooling_backoff,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = _data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_pooling_pending)

    {:keep_state_and_data,
     [
       {:state_timeout, pooling_backoff * 1_000, :pooling_timeout}
     ]}
  end

  def handle_event(
        :info,
        {_ref, %TransactionFailedResponse{reason: reason} = response},
        _state,
        %{
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_failed)

    {:next_state, :error_state, %{data | final_message: reason, messages: [response | messages]}}
  end

  def handle_event(
        :info,
        {_ref, %TransactionUndefinedResponse{} = response},
        _state,
        %{
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            max_retries: retries,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          },
          retries: retries
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_undefined)

    {:next_state, :error_state,
     %{
       data
       | final_message: "The transaction was tried #{retries + 1} times but was not accepted",
         messages: [response | messages]
     }}
  end

  def handle_event(
        :info,
        {_ref, %TransactionUndefinedResponse{} = response},
        _state,
        %{
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            backoff: backoff,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          },
          retries: retries
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_undefined)

    {:next_state, :retry_needed, %{data | retries: retries + 1, messages: [response | messages]},
     [
       {:state_timeout, backoff * 1_000, :backoff_timeout}
     ]}
  end

  def handle_event(
        :info,
        {_ref, %TransactionErrorResponse{} = response},
        _state,
        %{
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            backoff: backoff,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          },
          retries: retries
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:error, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_error)

    {:next_state, :retry_needed, %{data | retries: retries + 1, messages: [response | messages]},
     [
       {:state_timeout, backoff * 1_000, :backoff_timeout}
     ]}
  end

  def handle_event(
        :info,
        {_ref, %TransactionSuccessfulResponse{} = response},
        _state,
        %{
          ref: __ref,
          params: %{
            ref: id
          },
          messages: messages,
          this: %{
            transaction_timeout: transaction_timeout,
            pooling_backoff: pooling_backoff,
            payment_service_monitor: payment_service_monitor,
            payment_service_metrics: payment_service_metrics
          }
        } = data
      ) do
    maybe_notify_service_monitor(payment_service_monitor, {:ok, id})
    maybe_count_service_metrics(payment_service_metrics, :transaction_success)

    {:next_state, :waiting_for_callback,
     %{data | messages: [response | messages], started_time: DateTime.now!("Etc/UTC")},
     [
       {{:timeout, :generic_timeout1}, transaction_timeout * 1_000, :transaction_timeout},
       {:state_timeout, pooling_backoff * 1_000, :pooling_timeout}
     ]}
  end

  def handle_event(
        {:timeout, :generic_timeout1},
        :transaction_timeout,
        :waiting_for_callback,
        data
      ) do
    {:next_state, :error_state,
     %{data | final_message: "The transaction hasn't received the callback response"}}
  end

  def handle_event(
        :state_timeout,
        :pooling_timeout,
        :waiting_for_callback,
        %{
          this: %{
            payment_service_metrics: payment_service_metrics,
            pooling_params_formater: pooling_params_formater,
            pooling_http_request_processor: pooling_http_request_processor,
            pooling_http_response_processor: pooling_http_response_processor
          },
          transaction_type: transaction_type,
          params: params
        } = data
      ) do
    maybe_count_service_metrics(
      payment_service_metrics,
      :transaction_pooling_request,
      transaction_type
    )

    pooling_ref =
      Task.async(fn ->
        with prms <-
               Types.EndpointRequestParamsFormater.get_req_params(pooling_params_formater, params),
             result <- Types.HTTPClientRequest.execute(pooling_http_request_processor, prms) do
          Types.HTTPClientResponse.process_response(pooling_http_response_processor, result)
        end
      end).ref

    {:keep_state, %{data | pooling_ref: pooling_ref}}
  end

  def handle_event(
        :state_timeout,
        :backoff_timeout,
        :retry_needed,
        %{
          transaction_type: transaction_type,
          params: %{
            ref: ref
          }
        } = data
      ) do
    Throttler.Producer.add_event({ref, transaction_type})
    {:next_state, :waiting_for_throttling, data}
  end

  def handle_event(:info, {:DOWN, _, :process, _pid, :normal}, _state, _data) do
    {:keep_state_and_data, []}
  end

  def handle_event(:info, _, _state, _data) do
    {:keep_state_and_data, []}
  end

  @impl true
  def handle_event(
        :enter,
        :waiting_for_throttling,
        state,
        %{
          transaction_type: transaction_type,
          this: %{
            payment_service_metrics: payment_service_metrics,
            params_formater: params_formater,
            http_request_processor: http_request_processor,
            http_response_processor: http_response_processor
          },
          params: params
        } = data
      )
      when state == :waiting_for_throttling or state == :request_ticket do
    maybe_count_service_metrics(payment_service_metrics, :transaction_request, transaction_type)

    ref =
      Task.async(fn ->
        with prms <- Types.EndpointRequestParamsFormater.get_req_params(params_formater, params),
             result <- Types.HTTPClientRequest.execute(http_request_processor, prms) do
          Types.HTTPClientResponse.process_response(http_response_processor, result)
        end
      end).ref

    {:keep_state, %{data | ref: ref}}
  end

  @impl true
  def handle_event(
        :enter,
        :waiting_for_callback = _event,
        :ok_state = _state,
        %{
          transaction_type: txn_type,
          params: %{
            ref: ref
          },
          this: %{
            ok_callback: ok_callback,
            payment_service_metrics: payment_service_metrics
          }
        } = _data
      ) do
    maybe_notify_final_result(
      ok_callback,
      %{ref: ref, status: :success, txn_type: txn_type}
    )

    maybe_count_service_metrics(payment_service_metrics, :transaction_ok_ended)

    :stop
  end

  @impl true
  def handle_event(
        :enter,
        _event,
        :error_state = _state,
        %{
          transaction_type: txn_type,
          final_message: final_message,
          params: %{
            ref: ref
          },
          this: %{
            error_callback: error_callback,
            payment_service_metrics: payment_service_metrics
          }
        } = _data
      ) do
    maybe_notify_final_result(
      error_callback,
      %{ref: ref, status: :failed, txn_type: txn_type, reason: final_message}
    )

    maybe_count_service_metrics(payment_service_metrics, :transaction_error_ended)

    :stop
  end

  @impl true
  def handle_event(:enter, _event, _state, data) do
    {:keep_state, data}
  end

  def handle_event(:cast, :ready_for_request, _state, data) do
    {:next_state, :request_ticket, data}
  end

  def handle_event(
        :cast,
        {:ok_result, response},
        :waiting_for_callback,
        %{messages: messages} = data
      ) do
    response = %GeneralResponse{
      type: :ok_result,
      body: response
    }

    {:next_state, :ok_state, %{data | messages: [response | messages]}}
  end

  def handle_event(
        :cast,
        {:error_result, response},
        :waiting_for_callback,
        %{messages: messages} = data
      ) do
    msg_response = %GeneralResponse{
      type: :error_result,
      body: response
    }

    {:next_state, :error_state,
     %{data | final_message: response, messages: [msg_response | messages]}}
  end

  def handle_event(
        :cast,
        {:retry_queue, _reason},
        _state,
        %{
          this: %{
            backoff: backoff
          },
          retries: retries
        } = data
      ) do
    {:next_state, :retry_needed, %{data | retries: retries + 1},
     [{:state_timeout, backoff * 1_000, :backoff_timeout}]}
  end

  def handle_event(:cast, {:cancel, reason}, _state, %{messages: messages} = data) do
    response = %GeneralResponse{
      type: :cancel,
      body: reason
    }

    {:next_state, :error_state, %{data | final_message: reason, messages: [response | messages]}}
  end

  @impl true
  def init(
        {state,
         %{
           this: %{
             transaction_timeout: transaction_timeout,
             pooling_backoff: pooling_backoff,
             backoff: backoff
           }
         } = data}
      ) do
    Process.flag(:trap_exit, true)

    actions =
      cond do
        state == :waiting_for_callback and Map.get(data, :restarting, false) ->
          [
            {{:timeout, :generic_timeout1}, transaction_timeout * 1_000, :transaction_timeout},
            {:state_timeout, pooling_backoff * 1_000, :pooling_timeout}
          ]

        state == :retry_needed and Map.get(data, :restarting, false) ->
          {:state_timeout, backoff * 1_000, :backoff_timeout}

        true ->
          []
      end

    #    actions = []
    {:ok, state, data, actions}
  end

  @impl true
  def terminate(
        _reason,
        state,
        %{
          this: %{
            payment_service_buffer_writer: payment_service_buffer_writer
          },
          params: params,
          transaction_type: transaction_type,
          started_time: started_time,
          messages: messages
        } = _data
      )
      when state in [:ok_state, :error_state] do
    maybe_send_for_persistence(payment_service_buffer_writer, %{
      type: :finished,
      data: {transaction_type, params, messages, {started_time, DateTime.now!("Etc/UTC")}}
    })
  end

  @impl true
  def terminate(
        _reason,
        state,
        %{
          this: %{
            payment_service_buffer_writer: payment_service_buffer_writer
          },
          params: params,
          transaction_type: transaction_type,
          started_time: started_time,
          messages: messages
        } = _data
      ) do
    maybe_send_for_persistence(payment_service_buffer_writer, %{
      type: :pending,
      data: {transaction_type, state, params, messages, started_time}
    })
  end

  def start_link(args) do
    GenStateMachine.start_link(
      __MODULE__,
      args,
      name: {
        :global,
        args
        |> elem(1)
        # todo: this depends on the payload structure!
        |> get_in([:params, :ref])
      }
    )
  end

  def maybe_notify_final_result(nil, _), do: nil

  def maybe_notify_final_result(this, params) do
    Types.TransactionResultNotificator.execute(
      this,
      params
    )
  end

  def maybe_notify_service_monitor(nil, _), do: nil

  def maybe_notify_service_monitor(this, params) do
    Task.async(fn ->
      Types.PaymentServiceMonitor.notify(
        this,
        params
      )
    end)
  end

  def maybe_count_service_metrics(nil, _, _), do: nil

  def maybe_count_service_metrics(this, param, service) do
    Types.PaymentServiceMetrics.count(
      this,
      param,
      service
    )
  end

  def maybe_count_service_metrics(nil, _), do: nil

  def maybe_count_service_metrics(this, params) do
    Types.PaymentServiceMetrics.count(
      this,
      params
    )
  end

  def maybe_send_for_persistence(nil, _), do: nil

  def maybe_send_for_persistence(this, %{type: :pending, data: data} = _event) do
    Types.PaymentServiceBufferWriter.insert_pending_transaction(this, data)
  end

  def maybe_send_for_persistence(this, %{type: :finished, data: data} = _event) do
    Types.PaymentServiceBufferWriter.insert_finished_transaction(this, data)
  end
end
