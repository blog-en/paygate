defmodule MTNTokenProvider do
  @moduledoc false

  require Logger

  defstruct [
    :id,
    :params_formater,
    :http_request_processor,
    :http_response_processor,
    notificator: nil,
    reset_delta: 10,
    recovery_from_error_time: 5
  ]

  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  def handle_event(
        :info,
        {ref, {:ok, %{token: token, life_time: life_time}, _extra_info}},
        _state,
        %{
          ref: ref,
          this: %{
            id: id,
            reset_delta: reset_delta,
            notificator: notificator
          }
        } = data
      ) do
    :persistent_term.put(id, %{token: token})

    maybe_send_notification(notificator, :token_service_up)

    {
      :next_state,
      :token_active,
      data,
      [
        {:state_timeout, (life_time - reset_delta) * 1_000, :token_expired}
      ]
    }
  end

  def handle_event(
        :info,
        {ref, {:error, _, _}},
        _state,
        %{
          ref: ref,
          this: %{
            notificator: notificator,
            id: id,
            recovery_from_error_time: recovery_from_error_time
          }
        } = data
      ) do
    :persistent_term.put(id, %{token: {:error, :token_error}})

    maybe_send_notification(notificator, :token_service_down)

    {
      :next_state,
      :token_error,
      data,
      [
        {:state_timeout, recovery_from_error_time * 1_000, :token_request}
      ]
    }
  end

  def handle_event(:state_timeout, :token_request, :token_error, data) do
    {:next_state, :token_needed, data}
  end

  def handle_event(:state_timeout, :token_expired, :token_active, data) do
    {:next_state, :token_needed, data}
  end

  def handle_event(:info, {:DOWN, ref, :process, _pid, :normal}, _state, %{ref: ref}) do
    {:keep_state_and_data, []}
  end

  @impl true
  def handle_event(:enter, _event, :token_needed = _state, %{this: this} = data) do
    ref =
      Task.async(fn ->
        with prms <-
               Types.EndpointRequestParamsFormater.get_req_params(this.params_formater, %{}),
             result <- Types.HTTPClientRequest.execute(this.http_request_processor, prms) do
          Types.HTTPClientResponse.process_response(this.http_response_processor, result)
        end
      end).ref

    {:keep_state, %{data | ref: ref}}
  end

  @impl true
  def handle_event(:enter, _event, _state, data) do
    {:keep_state, data}
  end

  def start_link(args) do
    GenStateMachine.start_link(__MODULE__, args)
  end

  def maybe_send_notification(nil, _), do: nil

  def maybe_send_notification(this, param) when is_atom(param) do
    Types.StatusNotificator.notify(
      this,
      {param, nil}
    )
  end

  defimpl Types.TokenProvider do
    def get(this) do
      :persistent_term.get(this.id)
      |> Map.get(:token)
    end
  end
end
