defmodule HTTPTransactionResultNotificator do
  @moduledoc false

  defstruct [
    :params_formater,
    :http_request_processor
  ]

  require Logger

  defimpl Types.TransactionResultNotificator do
    def execute(this, params) do
      with prms <-
             Types.EndpointRequestParamsFormater.get_req_params(this.params_formater, params) do
        Types.HTTPClientRequest.execute(this.http_request_processor, prms)
      end
    end
  end
end
